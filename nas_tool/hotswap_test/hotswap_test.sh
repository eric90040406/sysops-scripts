#! /bin/sh
#################### init script + default variables ####################
current_path="$(realpath $(dirname $0))"
script_name="$(echo $(basename $0)|cut -d '.' -f1)"
if ! echo ${current_path}|grep -q 'log/tools' > /dev/null 2>&1; then
    main_script=0
    wget -N -r -l 0 --quiet -nd --timeout=30 --directory-prefix=${current_path}/${script_name}/log/tools --ftp-user=stressftp --ftp-password=ftp ftp://qc1.synology.qc/qc1script2/QC1_init/QC1_init.sh > /dev/null 2>&1
    chmod +x ${current_path}/${script_name}/log/tools/QC1_init.sh > /dev/null 2>&1; ${current_path}/${script_name}/log/tools/QC1_init.sh "${current_path}" "${script_name}" "${$}"; source ${current_path}/${script_name}/log/.bashrc > /dev/null 2>&1; source ${current_path}/${script_name}/log/.bashrc > /dev/null 2>&1; INIT_EXPORT > /dev/null 2>&1
    result_path="${INIT_CURRENT_PATH}"
    log_path="${INIT_LOG_PATH}"
else
    main_script=1
    source ${current_path}/../.bashrc > /dev/null 2>&1; INIT_EXPORT > /dev/null 2>&1
    result_path="$(INIT_GET_LOG_PATH ${current_path} ${script_name})"
    log_path="${result_path}"
fi
################### your functions ####################
main_log=${log_path}/main.log
upload_log="no"
md_device=""
disk_target=""
timeout_sec=3600
fail_count=0

Get_md_disk_state(){  # echo [UU_] style bitmap for md_device
    local state
    state=$(grep -A2 "^${md_device}" /proc/mdstat | grep -o '\[[U_]*\]' | tr -d '[]')
    if [ -z "${state}" ]; then
        echo "?"
    else
        echo "${state}"
    fi
}

Get_mismatch_cnt(){
    cat "/sys/block/${md_device}/md/mismatch_cnt" 2>/dev/null || echo "N/A"
}

Is_rebuilding(){  # returns 0 if rebuild in progress
    grep -A4 "^${md_device}" /proc/mdstat | grep -qE 'recovery|resync'
}

Get_rebuild_progress(){
    local pct eta
    pct=$(grep -A4 "^${md_device}" /proc/mdstat | grep -o '[0-9]*\.[0-9]*%' | head -1)
    eta=$(grep -A4 "^${md_device}" /proc/mdstat | grep 'finish=' | sed 's/.*finish=\([^ ]*\).*/\1/')
    echo "${pct:-?} — ETA ${eta:-?}"
}

Wait_for_rebuild(){
    local elapsed=0
    while [ ${elapsed} -lt ${timeout_sec} ]; do
        if ! Is_rebuilding; then
            return 0
        fi
        INIT_LOG -i "*** rebuilding: $(Get_rebuild_progress) ***" ${main_log}
        sleep 30
        elapsed=$(expr ${elapsed} + 30)
    done
    return 1
}

Main(){
    INIT_LOG -i "***** hotswap_test start — ${disk_target} in /dev/${md_device} *****" ${main_log}
    if [ "$(id -u)" -ne 0 ]; then
        INIT_LOG -e "ERROR: must run as root" ${main_log}
        exit 1
    fi
    INIT_LOG -i "*** initial state    : $(Get_md_disk_state) ***" ${main_log}
    INIT_LOG -i "*** initial mismatch : $(Get_mismatch_cnt) ***" ${main_log}
    INIT_LOG -i "======== Step [1/4] deactivating ${disk_target} ========" ${main_log}
    synostgdisk --disk-deactivate "${disk_target}"
    sleep 5
    local state
    state=$(Get_md_disk_state)
    INIT_LOG -i "*** MD state after deactivate: ${state} ***" ${main_log}
    case "${state}" in
        *_*)
            INIT_LOG -i "*** PASS: MD entered degraded state ***" ${main_log}
            ;;
        *)
            INIT_LOG -e "FAIL: MD did not go degraded (state=${state})" ${main_log}
            fail_count=$(expr ${fail_count} + 1)
            ;;
    esac
    INIT_LOG -i "======== Step [2/4] re-activating ${disk_target} ========" ${main_log}
    rm -f "/run/synostorage/disks/$(basename ${disk_target})/deactivated" > /dev/null 2>&1
    sleep 10
    INIT_LOG -i "*** disk re-activated ***" ${main_log}
    INIT_LOG -i "======== Step [3/4] waiting for rebuild (timeout: ${timeout_sec}s) ========" ${main_log}
    if Wait_for_rebuild; then
        INIT_LOG -i "*** PASS: rebuild completed ***" ${main_log}
    else
        INIT_LOG -e "FAIL: rebuild timed out after ${timeout_sec}s" ${main_log}
        fail_count=$(expr ${fail_count} + 1)
    fi
    INIT_LOG -i "======== Step [4/4] verifying final state ========" ${main_log}
    local final_state final_mismatch
    final_state=$(Get_md_disk_state)
    final_mismatch=$(Get_mismatch_cnt)
    INIT_LOG -i "*** final MD state   : ${final_state} ***" ${main_log}
    INIT_LOG -i "*** final mismatch   : ${final_mismatch} ***" ${main_log}
    case "${final_state}" in
        *_*)
            INIT_LOG -e "FAIL: MD still degraded after rebuild (state=${final_state})" ${main_log}
            fail_count=$(expr ${fail_count} + 1)
            ;;
        *)
            INIT_LOG -i "*** PASS: all disks active in /dev/${md_device} ***" ${main_log}
            ;;
    esac
    if [ "${final_mismatch}" = "0" ]; then
        INIT_LOG -i "*** PASS: mismatch_cnt = 0 ***" ${main_log}
    else
        INIT_LOG -e "FAIL: mismatch_cnt = ${final_mismatch}" ${main_log}
        fail_count=$(expr ${fail_count} + 1)
    fi
    if [ ${fail_count} -eq 0 ]; then
        INIT_LOG -i "***** RESULT: PASS *****" ${main_log}
    else
        INIT_LOG -e "RESULT: FAIL (${fail_count} issue(s))" ${main_log}
        exit 1
    fi
}
################### get Value from keyin ####################
Get_keyin(){
    for this_arg in ${@}; do
        key=`echo ${this_arg} | cut -d= -f 1`
        value=`echo ${this_arg} | cut -d= -f 2`
        case ${key} in
            --md)
                md_device=$(basename ${value})
                ;;
            --disk)
                disk_target=${value}
                ;;
            --timeout)
                timeout_sec=${value}
                ;;
            finish)
                QC1_remote_log_handler.sh finish
                exit
                ;;
            reset)   #must have
                INIT_RESET_SCRIPT ${current_path} ${script_name}; exit
                ;;
            stop)   #must have
                QC1_remote_log_handler.sh finish
                INIT_STOP_SCRIPT ${current_path} ${script_name}; exit
                ;;
            *|--help)      #must have
                echo "=================== Here is the Usage for this script ==============="
                echo "reset                    Delete all files in ${result_path}"
                echo "stop                     Stop test"
                echo "--md=/dev/mdX            MD RAID device (required)"
                echo "--disk=/dev/sdX          Disk device to hot-swap (required)"
                echo "--timeout=N              Rebuild wait timeout in seconds (default: ${timeout_sec})"
                exit
                ;;
        esac
    done
    if [ -z "${md_device}" ] || [ -z "${disk_target}" ]; then
        INIT_LOG -e "ERROR: --md and --disk are required" ${main_log}
        exit 1
    fi
}
####################################### main loop ############################################
Get_keyin ${@} && if [ -f ${INIT_LOG_PATH}/process_running ]; then rm ${INIT_LOG_PATH}/process_running >/dev/null 2>&1; exit; fi
Main
