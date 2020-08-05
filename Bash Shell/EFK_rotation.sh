#! /bin/bash

# run the script as root user
log_dir=$1
today=`date +%Y%m%d`


function backup_log(){
for stuff in `ls ${log_dir}`;do

    # if the ${stuff} is the log file
    if [ -f ${log_dir}/${stuff} ];then
    record=`du -sb ${log_dir}/${stuff}`
    size_byte=`echo ${record}|awk '{print $1}'`
    size=$[${size_byte}/1024]
        if [ ${size} -gt 10240 ];then
        echo -n "${log_dir}/${stuff} is larger than 10MB, deleting..  "
        cp ${log_dir}/${stuff} ${log_dir}/${stuff}.${today} && \
        cat /dev/null > ${log_dir}/${stuff}
        [ $? -eq 0 ] && echo "OK" || echo "Failed"
        fi

    # if the ${stuff} is tomcat or nginx directory, but not "not_match"
    # because "not_match" contains the file which is used for debug, not source log.
    elif [ -d ${log_dir}/${stuff} ] && [ "${stuff}" != "not_match" ];then
        log_dir=${log_dir}/${stuff}
        backup_log ${log_dir}
        log_dir=$1
    fi

done
}

#====================================================================

echo -e "====================${today}==================\n"
if [ ! -d ${log_dir} ] || [ "${log_dir}x" == "x" ] || [[ ${log_dir} =~ /$ ]];then
echo "The 1st parameter must have and must be a directory which is not end with "/", Aborting.."
exit 1
fi

# delete the backuped log whose mtime is lagger than 10

find ${log_dir} -mtime +10 -name "*.log.*" -exec rm -rf {} \;

# Cp the log file to .log.<date +%Y%m%d> when the size is bigger than 15MB
# clean the log file but don't delete it
# just run the function defined top

backup_log ${log_dir}

echo "EFK source log rotation complete."