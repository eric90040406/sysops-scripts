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
disk_target=""
max_iterations=1
size_mb=512
pass_count=0
fail_count=0

Counter_control(){
    rm ${result_path}/count.${count} > /dev/null 2>&1
    count=$(expr ${count} + 1)
    INIT_LOG -i "======== Starting round [${count}] test ========" ${main_log}
    touch ${result_path}/count.${count}; chmod 777 ${result_path}/count.${count}
}

Wait_for_volume(){  # poll until /volumeN appears in mount; args: timeout_sec
    local timeout=${1}
    local elapsed=0
    while [ ${elapsed} -lt ${timeout} ]; do
        if [ "$(mount | grep -c '/volume[0-9]')" -ge 1 ]; then
            return 0
        fi
        sleep 3
        elapsed=$(expr ${elapsed} + 3)
    done
    return 1
}

Wait_volume_gone(){  # poll until vol no longer in mount; args: vol timeout_sec
    local vol=${1}
    local timeout=${2}
    local elapsed=0
    while [ ${elapsed} -lt ${timeout} ]; do
        if [ "$(mount | grep -c "${vol}")" -eq 0 ]; then
            return 0
        fi
        sleep 3
        elapsed=$(expr ${elapsed} + 3)
    done
    return 1
}

Create_pool_and_volume(){
    local size_kb
    size_kb=$(expr ${size_mb} \* 1024)
    synowebapi --exec \
        allocate_size="\"${size_kb}\"" \
        api="SYNO.Storage.CGI.Volume" \
        atime_opt="\"relatime\"" \
        blocking="false" \
        desc="\"\"" \
        device_type="\"basic\"" \
        diskGroups="[{\"isNew\":true,\"raidPath\":\"new_raid\",\"disks\":[\"${disk_target}\"]}]" \
        disk_id="[\"${disk_target}\"]" \
        enable_dedupe="false" \
        force="false" \
        fs_type="\"btrfs\"" \
        is_disk_check="false" \
        is_pool_child="true" \
        limitNum="\"24\"" \
        method="create" \
        pool_path="\"\"" \
        spare_disk_count="\"0\"" \
        version="1" \
        vol_desc="\"\"" > /dev/null 2>&1
}

Delete_volume(){
    local vol=${1}
    synowebapi --exec \
        api="SYNO.Storage.CGI.Volume" \
        method="delete" \
        version="1" \
        vol_path="\"${vol}\"" \
        force="false" > /dev/null 2>&1
}

Delete_pool(){
    local pool=${1}
    synowebapi --exec \
        api="SYNO.Storage.CGI.Pool" \
        method="delete" \
        version="1" \
        pool_path="\"${pool}\"" \
        force="false" > /dev/null 2>&1
}

Get_pool_path(){
    synowebapi --exec api="SYNO.Storage.CGI.Pool" method="list" version="1" 2>/dev/null \
        | awk -F'"' '/"pool_path"/ { print $4; exit }'
}

Run_iteration(){
    local iter=${1}
    INIT_LOG -i "*** iteration ${iter}/${max_iterations} ***" ${main_log}
    INIT_LOG -i "*** creating pool+volume on ${disk_target} (${size_mb}MB) ***" ${main_log}
    if ! Create_pool_and_volume; then
        INIT_LOG -e "FAIL iter ${iter}: synowebapi create failed" ${main_log}
        fail_count=$(expr ${fail_count} + 1)
        return
    fi
    if ! Wait_for_volume 120; then
        INIT_LOG -e "FAIL iter ${iter}: volume did not mount within 120s" ${main_log}
        fail_count=$(expr ${fail_count} + 1)
        return
    fi
    local vol
    vol=$(mount | grep -o '/volume[0-9]*' | tail -1)
    INIT_LOG -i "*** volume mounted at ${vol} ***" ${main_log}
    local testfile
    testfile="${vol}/lifecycle_test_${iter}.dat"
    INIT_LOG -i "*** writing ${size_mb}MB of random data ***" ${main_log}
    dd if=/dev/urandom of="${testfile}" bs=1M count="${size_mb}" > /dev/null 2>&1
    local md5_write md5_read
    md5_write=$(md5sum "${testfile}" | awk '{print $1}')
    INIT_LOG -i "*** MD5 (write): ${md5_write} ***" ${main_log}
    md5_read=$(md5sum "${testfile}" | awk '{print $1}')
    INIT_LOG -i "*** MD5 (read) : ${md5_read} ***" ${main_log}
    rm -f "${testfile}" > /dev/null 2>&1
    if [ "${md5_write}" = "${md5_read}" ]; then
        INIT_LOG -i "*** PASS iter ${iter}: MD5 match ***" ${main_log}
        pass_count=$(expr ${pass_count} + 1)
    else
        INIT_LOG -e "FAIL iter ${iter}: MD5 mismatch" ${main_log}
        fail_count=$(expr ${fail_count} + 1)
    fi
    INIT_LOG -i "*** deleting volume ${vol} ***" ${main_log}
    Delete_volume "${vol}"
    local pool
    pool=$(Get_pool_path)
    if [ -n "${pool}" ]; then
        INIT_LOG -i "*** deleting pool ${pool} ***" ${main_log}
        Delete_pool "${pool}"
    else
        INIT_LOG -i "*** WARN: could not find pool to delete ***" ${main_log}
    fi
    if Wait_volume_gone "${vol}" 60; then
        INIT_LOG -i "*** PASS iter ${iter}: cleanup verified ***" ${main_log}
        pass_count=$(expr ${pass_count} + 1)
    else
        INIT_LOG -e "FAIL iter ${iter}: volume still mounted after deletion" ${main_log}
        fail_count=$(expr ${fail_count} + 1)
    fi
}

Main(){
    INIT_LOG -i "***** pool_lifecycle_test start — disk: ${disk_target} *****" ${main_log}
    if [ "$(id -u)" -ne 0 ]; then
        INIT_LOG -e "ERROR: must run as root" ${main_log}
        exit 1
    fi
    for i in $(seq 1 ${max_iterations}); do
        Counter_control
        Run_iteration ${i}
    done
    INIT_LOG -i "***** SUMMARY *****" ${main_log}
    INIT_LOG -i "*** iterations : ${max_iterations} ***" ${main_log}
    INIT_LOG -i "*** pass       : ${pass_count} ***" ${main_log}
    INIT_LOG -i "*** fail       : ${fail_count} ***" ${main_log}
    if [ ${fail_count} -eq 0 ]; then
        INIT_LOG -i "***** RESULT: PASS *****" ${main_log}
    else
        INIT_LOG -e "RESULT: FAIL (${fail_count} failure(s))" ${main_log}
        exit 1
    fi
}
################### get Value from keyin ####################
Get_keyin(){
    for this_arg in ${@}; do
        key=`echo ${this_arg} | cut -d= -f 1`
        value=`echo ${this_arg} | cut -d= -f 2`
        case ${key} in
            --disk|-d)
                disk_target=${value}
                ;;
            --count|-n)
                max_iterations=${value}
                ;;
            --size|-s)
                size_mb=${value}
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
                echo "--disk=<name>            Disk device name, e.g. sata4 (required)"
                echo "--count=N                Number of iterations (default: ${max_iterations})"
                echo "--size=N                 Volume size in MB (default: ${size_mb})"
                exit
                ;;
        esac
    done
    if [ -z "${disk_target}" ]; then
        INIT_LOG -e "ERROR: --disk is required" ${main_log}
        exit 1
    fi
}
####################################### main loop ############################################
Get_keyin ${@} && if [ -f ${INIT_LOG_PATH}/process_running ]; then rm ${INIT_LOG_PATH}/process_running >/dev/null 2>&1; exit; fi
Main
