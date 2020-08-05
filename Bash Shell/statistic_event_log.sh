#!/usr/bin/env bash



#!/bin/bash

# Yuxiao
# this script is for operation team to statistic the imei/uid in fe-log on the specified date
# this script should run as iot-user@gk4 or gk5

rel_dir=`dirname $0`
curr_dir=`cd ${rel_dir};pwd`
abs_dir=${rel_dir}
fe_log_dir=/data/var
#today=`date +%Y%m%d`
yesterday=`date -d yesterday +%Y%m%d`
fe_record=`cat fe_hosts.txt`
event_type="store_fetch_manifest"

# verify $1
if [ "x$1" = "x" ];then
    echo "[Wrong] please input a 8 digit number date, like 20190101" && exit
elif [[ "$1" =~ ^[0-9]{8}$ ]];then
    thedate=$1
else
    echo "[Wrong] wrong formate, should like 20190101" && exit
fi

# filter manifest API log and fetch the created file to gk locall
echo "====start collect log for fe hosts====="

for line in ${fe_record};do
    ip=`echo ${line}|awk -F, '{print $1}'`
    host=`echo ${line}|awk -F, '{print $2}'`
    ssh ${ip} "sudo su - cumulis -c 'grep ${event_type} ${fe_log_dir}/*${thedate}*'"
done> full_fe.log

[ $? = 0 ] && echo "full fe log collect OK" || {
echo "[Error] full fe log collect Failed,Aborting"
exit
}

# filter full_fe.log

uid_list=`grep  -i -Po '\"device_uid(\S+)Kaiversion' full_fe.log |sed 's/,"KaiVersion//g'|uniq -c |sort -rk 1|sed 's/\s\+//g'`
echo  "${uid_list}" > uid_list.txt

for line in `cat uid_list.txt ` ;do
    frequency=`echo ${line}|awk -F '"' '{print $1}'`
    if [ ${frequency} -gt 10 ];then
    	echo "${line}"
    else
    	break
    fi
done > dangerous_uid_`date +%Y%m%d`.txt

[ $? = 0 ] && echo "dangerous uid collect OK" || {
echo "[Error] full  collect Failed,Aborting"
exit
}

=========================improvement==============

we can't use top last method:
# filter full_fe.log

uid_list=`grep  -i -Po '\"device_uid(\S+)Kaiversion' full_fe.log |sed 's/,"KaiVersion//g'|uniq -c |sort -rk 1|sed 's/\s\+//g'`
echo  "${uid_list}" > uid_list.txt

for line in `cat uid_list.txt ` ;do
    frequency=`echo ${line}|awk -F '"' '{print $1}'`
    if [ ${frequency} -gt 10 ];then
    	echo "${line}"
    else
    	break
    fi
done > dangerous_uid_`date +%Y%m%d`.txt

[ $? = 0 ] && echo "dangerous uid collect OK" || {
echo "[Error] full  collect Failed,Aborting"
exit
}
===========================================================
it is complicate:
we can use below:

# filter full_fe.log
echo "====${yesterday}-${envioment}====" >
uid_list=`grep  -i -Po '\"device_uid(\S+)Kaiversion' full_fe.log |sed 's/,"KaiVersion//g'|sort|uniq -c |sort -nrk 1|
awk '{if ($1 > 50){print $0}}'
echo  "${uid_list}" > uid_list.txt

this is simple







