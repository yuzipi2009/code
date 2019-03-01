#!/bin/bash

rel_dir=`dirname $0`
current_dir=`cd ${rel_dir};pwd`
abs_dir=${current_dir}
local_log_dir="/home/iot-user/routine_check_log"
#cloud_log_dir="/data/tools/repository/empowerthings"
#cloud_log_dir="/data/var"
cloud_log_dir="/data/tools/repository/empowerthings"


to="xiao.yu@kaiostech.com"


server_list_hkk1=(
10.81.70.135
10.81.70.136
10.81.70.137
10.81.70.138
10.81.70.139
10.81.70.140
)


server_list=(
172.31.10.219
172.31.18.12
172.31.33.1
172.31.11.180
172.31.44.123
172.31.15.221
172.31.41.139
)

server_list_old=(
192.168.51.200
192.168.65.212
192.168.49.32
192.168.66.212
192.168.52.119
192.168.66.71
)
server_list_temp=(
192.168.49.59-dla
192.168.69.143-dlc
)

url_list=(
https://developer.kaiostech.com/devlogin
https://developer.stage.kaiostech.com/devlogin
https://services.stage.kaiostech.com/antitheft
https://services.kaiostech.com/antitheft
https://developer.stage.kaiostech.com/subpo
)

today=`date -d today +"%Y-%m-%d %T"`
today_s=`date -d "${today}" +%s`
SHdate=`TZ='Asia/Shanghai' date -d today +"%Y-%m-%d %T"`


## 0) check ssh avaliability
function check_ssh()
{
${abs_dir}/send_message_all.sh "   <${SHdate}> \n-Start System Routine Check- \n  1.Check SSH Avaliability"
for ip in ${server_list[*]}
do
ssh ${ip} -o ConnectTimeout=3 "exit"
if [ $? -ne 0 ];then
    ${abs_dir}/send_message_all.sh "[fatal failed]  ssh check failed, aborting system check"
    exit 5
else
    ${abs_dir}/send_message_op.sh "[ok] ${ip}:  ssh check pass"
fi
done
}


## 1) check whether there are Error in fe/ll/dl logs, panic in *.out
function check_error()
{
${abs_dir}/send_message_all.sh "  2.Start Log Error Check"

for ip in ${server_list[*]}
do

   # obtain the hostname
    node=`ssh ${ip} -o ConnectTimeout=3 "hostname"`
    host=`echo ${node}|cut -d '-' -f 3-5`

    #check .log
    error_record=`ssh ${ip} -o ConnectTimeout=3 "sudo grep -i -a -w 'Eror' ${cloud_log_dir}/*.log|egrep -v -i -w 'expired|missing|invalid|not found|error req|no order found|doesn'\''t match|password|account|bad time stamp|blacklisted|not authorized|Cache return nil value'"`
    if [ ${error_record}"x" = "x" ];then
	    ${abs_dir}/send_message_op.sh "[ok]  ${host}: no system error is found in the Log"
	else
        ${abs_dir}/send_message_all.sh "[error]  ${host}: found error in the log! \n${error_record}"
    fi

   #check .out
    panic_record=`ssh ${ip} -o ConnectTimeout=3 "sudo egrep -i -a -w 'Exception|panic' ${cloud_log_dir}/*.out"`
	if [ ${panic_record}"x" = "x" ];then
	    ${abs_dir}/send_message_op.sh "[ok]  ${host}: no system panic is found in the out file"
	else
        ${abs_dir}/send_message_all.sh "[error]  ${host}: found panic in the out file! \n${panic_record}"
    fi

done
sleep 1
}


## 2) check whether fe/fe3/fe-idm/ll3/dl3 processes are running

function check_process()
{

${abs_dir}/send_message_all.sh "  3.Start Cloud Process Check"
for ip in ${server_list[*]}
do

    # obtain the hostname
    node=`ssh ${ip} -o ConnectTimeout=3 "hostname"`
    host=`echo ${node}|cut -d '-' -f 3-5`

    process_stat=`ssh ${ip} "sudo su - cumulis -c 'ps -ef'"`
    process_stat_filter=`echo "${process_stat}"|egrep -w "bin/cumulis_fe3|bin/cumulis_ll3|bin/cumulis_dl3"|grep -v grep|awk '{print $1}'`
    if [ ${process_stat_filter}"x" = "x" ];then
	   ${abs_dir}/send_message_all.sh "[error]  ${host} process is down!"
    else
       ${abs_dir}/send_message_op.sh "[ok]  ${host} process is up!"
    fi
    sleep 1
done
sleep 1
}


## 3) check whether the fe/ll/dl logs are updated in time
function check_update()
{
${abs_dir}/send_message_all.sh "  4.Start Log Update Check"
for ip in ${server_list[*]}
do

    # obtain the hostname
    node=`ssh ${ip} -o ConnectTimeout=3 "hostname"`
    host=`echo ${node}|cut -d '-' -f 3-5`

    # log_date is the date of the current log, log_date_s change the formate to second
    log_date=`ssh ${ip} -o ConnectTimeout=3 "sudo stat -c %y ${cloud_log_dir}/*.log"`
    log_date_format=`echo ${log_date}|awk -F "." '{print $1}'`
    log_date_s=`date -d "${log_date_format}" +%s`
    time_interval=$($(${today_s}-${log_date_s})/3600)

    if [   ${time_interval} -gt 12 ];then
        ${abs_dir}/send_message_all.sh "[error]  ${host} log is not updated over 12 hours!"
    else
        ${abs_dir}/send_message_op.sh "[ok]  ${host} log is updated ${time_interval} hours ago"
    sleep 1
    fi
done
sleep 1
}


## 4) check whether submission portal url is normal
function check_url()
{
${abs_dir}/send_message_all.sh "  5.Start Web URL Check"
for url in ${url_list[*]}
do
    echo "----------URLNAME:${url}----------TODAY is:${today}-------------"
    url_stat=`curl -s --head --request GET ${url}|sed -n '1p'|awk '{print $2}'|egrep "40*|50*"`
    url_sed=`echo ${url}|sed 's/.*\/\///'`

    if [ "${url_stat}x" = "x"  ];then
    ${abs_dir}/send_message_op.sh "[ok]  ${url_sed} is online"
    else
    ${abs_dir}/send_message_all.sh "[error]  ${url_sed}: ${url_stat}"
    fi
    sleep 2
done
${abs_dir}/send_message_all.sh "---Routine Check Complete--- \n    <${SHdate}>"
}

check_ssh
check_error
check_process
check_update
check_url