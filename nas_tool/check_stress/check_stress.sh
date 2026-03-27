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
fail_count=0

Check_section(){  # scan one log section; args: name cmd [cmd_args...]
    local name=${1}
    shift
    INIT_LOG -i "*** Checking: ${name} ***" ${main_log}
    local hits
    hits=$("${@}" 2>/dev/null) || true
    if [ -z "${hits}" ]; then
        INIT_LOG -i "${name}: (none)" ${main_log}
        touch ${result_path}/check.${name}.pass
    else
        INIT_LOG -i "${hits}" ${main_log}
        touch ${result_path}/check.${name}.fail
        fail_count=$(expr ${fail_count} + 1)
    fi
}

Print_summary(){
    INIT_LOG -i "***** SUMMARY *****" ${main_log}
    for section in panic DENIED core segfault calltrace; do
        if [ -f ${result_path}/check.${section}.fail ]; then
            INIT_LOG -i "  ${section}  FAIL" ${main_log}
        else
            INIT_LOG -i "  ${section}  pass" ${main_log}
        fi
    done
}

Main(){
    INIT_LOG -i "***** check_stress start — $(hostname) *****" ${main_log}
    rm -f ${result_path}/check.*.pass ${result_path}/check.*.fail > /dev/null 2>&1
    Check_section "panic"     grep -h panic    /var/log/messages /var/log/kern.log
    Check_section "DENIED"    grep -ih denied  /var/log/apparmor.log /var/log/kern.log
    Check_section "core"      find /volume1 /var/crash -maxdepth 2 -name "*core*"
    Check_section "segfault"  grep -h segfault /var/log/messages
    Check_section "calltrace" grep -h "Trace"  /var/log/messages
    Print_summary
    if [ ${fail_count} -eq 0 ]; then
        INIT_LOG -i "***** RESULT: PASS *****" ${main_log}
    else
        INIT_LOG -e "RESULT: FAIL (${fail_count} section(s) with hits)" ${main_log}
        exit 1
    fi
}
################### get Value from keyin ####################
Get_keyin(){
    for this_arg in ${@}; do
        key=`echo ${this_arg} | cut -d= -f 1`
        value=`echo ${this_arg} | cut -d= -f 2`
        case ${key} in
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
                echo "stop                     Stop check"
                exit
                ;;
        esac
    done
}
####################################### main loop ############################################
Get_keyin ${@} && if [ -f ${INIT_LOG_PATH}/process_running ]; then rm ${INIT_LOG_PATH}/process_running >/dev/null 2>&1; exit; fi
Main
