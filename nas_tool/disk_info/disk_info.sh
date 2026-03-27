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
output_json="no"
md_map_file="${result_path}/md_map.tmp"
devlist_file="${result_path}/devlist.tmp"

Build_md_map(){  # parse /proc/mdstat into a temp file: "devname /dev/mdX"
    rm -f ${md_map_file} > /dev/null 2>&1
    awk '
        /^md[0-9]+/ {
            md = $1
            for (i = 1; i <= NF; i++) {
                dev = $i
                gsub(/\[[0-9]+\].*/, "", dev)
                if (dev != md && dev ~ /^[a-z]/) {
                    print dev " /dev/" md
                }
            }
        }
    ' /proc/mdstat > ${md_map_file} 2>/dev/null
}

Get_md_for_dev(){  # echo md device path(s) for given dev name, or "none"
    local dev=${1}
    local md
    md=$(grep "^${dev} " ${md_map_file} 2>/dev/null | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    if [ -z "${md}" ]; then
        echo "none"
    else
        echo "${md}"
    fi
}

Get_smartctl_field(){  # echo trimmed value for a smartctl field; args: dev field_regex
    local dev=${1}
    local field=${2}
    smartctl -i "/dev/${dev}" 2>/dev/null \
        | awk -F: -v key="${field}" '$1 ~ key { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }'
}

Get_disk_type(){  # echo SSD or HDD based on rotational flag; args: dev
    local rot
    rot=$(cat "/sys/block/${1}/queue/rotational" 2>/dev/null || echo "1")
    if [ "${rot}" = "0" ]; then
        echo "SSD"
    else
        echo "HDD"
    fi
}

Print_table(){
    INIT_LOG -i "***** disk_info *****" ${main_log}
    printf '%-10s  %-4s  %-34s  %-8s  %-20s  %s\n' DEVICE TYPE MODEL SIZE SERIAL MD
    printf '%-10s  %-4s  %-34s  %-8s  %-20s  %s\n' '----------' '----' '----------------------------------' '--------' '--------------------' '--------'
    lsblk -dno NAME 2>/dev/null | grep -E '^(sd|nvme|hd)' > ${devlist_file} 2>/dev/null
    while read dev; do
        size=$(lsblk -dno SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")
        model=$(Get_smartctl_field "${dev}" "Device Model|Model Number")
        model=${model:-N/A}
        sn=$(Get_smartctl_field "${dev}" "Serial Number|Serial number")
        sn=${sn:-N/A}
        type=$(Get_disk_type "${dev}")
        md=$(Get_md_for_dev "${dev}")
        printf '%-10s  %-4s  %-34s  %-8s  %-20s  %s\n' "/dev/${dev}" "${type}" "${model}" "${size}" "${sn}" "${md}"
    done < ${devlist_file}
    INIT_LOG -i "*** /proc/mdstat ***" ${main_log}
    cat /proc/mdstat
    rm -f ${devlist_file} > /dev/null 2>&1
}

Print_json(){
    local dev_count line_num
    lsblk -dno NAME 2>/dev/null | grep -E '^(sd|nvme|hd)' > ${devlist_file} 2>/dev/null
    dev_count=$(wc -l < ${devlist_file})
    line_num=0
    echo "["
    while read dev; do
        size=$(lsblk -dno SIZE "/dev/${dev}" 2>/dev/null || echo "N/A")
        model=$(Get_smartctl_field "${dev}" "Device Model|Model Number")
        model=${model:-N/A}
        sn=$(Get_smartctl_field "${dev}" "Serial Number|Serial number")
        sn=${sn:-N/A}
        type=$(Get_disk_type "${dev}")
        md=$(Get_md_for_dev "${dev}")
        line_num=$(expr ${line_num} + 1)
        if [ ${line_num} -lt ${dev_count} ]; then
            printf '  {"device":"/dev/%s","type":"%s","model":"%s","size":"%s","serial":"%s","md":"%s"},\n' \
                "${dev}" "${type}" "${model}" "${size}" "${sn}" "${md}"
        else
            printf '  {"device":"/dev/%s","type":"%s","model":"%s","size":"%s","serial":"%s","md":"%s"}\n' \
                "${dev}" "${type}" "${model}" "${size}" "${sn}" "${md}"
        fi
    done < ${devlist_file}
    echo "]"
    rm -f ${devlist_file} > /dev/null 2>&1
}

Main(){
    INIT_LOG -i "***** disk_info start *****" ${main_log}
    if [ "$(id -u)" -ne 0 ]; then
        INIT_LOG -e "ERROR: must run as root" ${main_log}
        exit 1
    fi
    for cmd in smartctl lsblk mdadm; do
        if ! command -v "${cmd}" > /dev/null 2>&1; then
            INIT_LOG -e "ERROR: missing required command: ${cmd}" ${main_log}
            exit 1
        fi
    done
    Build_md_map
    if [ "${output_json}" = "yes" ]; then
        Print_json
    else
        Print_table
    fi
    rm -f ${md_map_file} > /dev/null 2>&1
    INIT_LOG -i "***** disk_info done *****" ${main_log}
}
################### get Value from keyin ####################
Get_keyin(){
    for this_arg in ${@}; do
        key=`echo ${this_arg} | cut -d= -f 1`
        value=`echo ${this_arg} | cut -d= -f 2`
        case ${key} in
            --json|-j)
                output_json="yes"
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
                echo "stop                     Stop"
                echo "--json | -j              Output JSON instead of plain text"
                exit
                ;;
        esac
    done
}
####################################### main loop ############################################
Get_keyin ${@} && if [ -f ${INIT_LOG_PATH}/process_running ]; then rm ${INIT_LOG_PATH}/process_running >/dev/null 2>&1; exit; fi
Main
