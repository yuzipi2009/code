#!/bin/bash


action=$1
conf_file=$2
script_dir=`dirname $0`
script_name=`basename $0`
abs_dir=`cd ${script_dir};pwd`
conf_dir=${abs_dir}/conf

#start: ./service.sh start
#stop: ./service.sh stop

case ${action} in
    start)

    if [ ! -f ${conf_dir}/config.txt ];then
        echo "Miss configuration file"
        exit
    fi

    nohup ./sign -conf=${conf_dir}/config.txt  > /dev/null 2>&1 &

    if [ $? -eq 0 ];then
        pid=$!
        echo ${pid} > sign.pid
        echo "start sign($pid) successfully"
    else
        echo "start sign failed"
    fi

    ;;

    stop)

    if [ ! -f sign.pid ];then
        echo "Miss pid file."
        exit
    else
        pid=`cat sign.pid`
        kill -15 $pid
        if [ $? -eq 0 ];then
            echo "Kill $pid scuuessfully"
        else
            echo "Kill $pid failed"
        fi
    fi
    ;;
esac
