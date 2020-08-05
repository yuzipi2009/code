#!/bin/bash

#Yuxiao-20190115
# this script is for QA team to collect all aids from 6 k4-redis server.
# this script should be run as iot-user@gk4

record=`cat redis_host.txt`
key_dir=~/.ssh/aws_iot_cloud.pem
redis_port="7000"
cli_dir=/data/tools/repository/redis/src


for line in ${record}; do
    ip=`echo ${line}|awk -F, '{print $1}'`
    hostname=`echo ${line}|awk -F, '{print $2}'`
    session_file="session_${hostname}.txt"
    aid_file=aid_${hostname}.txt


#generate all record keys session*

    session_keys=`ssh -i ${key_dir} ${ip} "sudo su - redis -c '
    ${cli_dir}/redis-cli -p ${redis_port} --scan --pattern 'session*''"`

    [ $? -eq 0 ] && echo "${hostname}: generate session data OK" || {
    echo "[ERROR] ${hostname}: generate session data Failed, Aborting"
    exit
    }

#echo the variable to a file

    echo -e ${session_keys} > ${session_file}

#get the value from key
    for session in `cat session_${hostname}.txt`; do
        ssh -i ${key_dir} ${ip} "sudo su - redis -c '
        ${cli_dir}/redis-cli -p ${redis_port} get ${session}'"
    done > ${aid_file}

    [ $? -eq 0 ] && rm -rf ${session_file} && echo "${hostname}: collect aid OK"|| {
    echo "[Error] ${hostname}: collect aid Failed, Aborting"
    exit
    }
done

#sort the 3 aid_file into one

cat aid*.txt |sort > full_aid_record_`date +%Y%m%d`.txt && rm -rf aid*.txt && echo "All aid records are generated"