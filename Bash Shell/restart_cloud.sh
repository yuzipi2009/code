#!/bin/bash

env=$1
layer_temp=$2
layer=${layer_temp}3

test_fe="10.81.74.135 10.81.74.136"
test_ll="10.81.74.137 10.81.74.138"
test_dl="10.81.74.139 10.81.74.140"

stage_fe="172.31.2.224 172.31.22.43"
stage_ll="172.31.14.7 172.31.30.198"
stage_dl="172.31.7.221 172.31.16.151"

layer_hosts=${env}_${layer_temp}
list=`eval echo '$'${layer_hosts}`

stage_user="iot-user"
test_user="kai-user"

stage_gk="34.193.231.19"
test_gk="10.81.76.19"

user=`eval echo '$'${env}_user`
gk=`eval echo '$'${env}_gk`


#echo "list is ${list}"
#echo "user is ${user}"
#echo "gk is ${gk}"


function restart_fell (){

    ssh ${user}@${gk} "ssh $host \"sudo su - cumulis -c 'kill -9 $pid; sleep 2 && cd /data/var/ && bin/start_service.sh ${layer} ./key_${env}.json'\""

}

function restart_dl (){

    #DL has a process list
    pidlist=$(ssh ${user}@${gk} "ssh $host \"sudo su -c \\\"pstree -pn ${pid}|grep -Po '\d{2,10}'\\\"\"")
    echo dl pid list is ${pidlist}
    #here $pidlist is a string, "$pidlist" is a list, ""$pidlisy"" is string(below)
    ssh ${user}@${gk} "ssh $host \"sudo su - cumulis -c 'kill -9 "$pidlist"; sleep 2 && cd /data/var/ && bin/start_service.sh ${layer} ./key_${env}.json'\""

}

for host in ${list};do
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
    echo "Working on $host:"
    if [ ! -f ./keys/key_${env}.json ];then
        echo " NO key, aborting"
        exit
    fi
    scp ./keys/key_${env}.json ${user}@${gk}:/tmp && ssh ${user}@${gk} "scp /tmp/key_${env}.json ${host}:/tmp && ssh ${host} \"sudo su -c 'chown cumulis: /tmp/key_${env}.json && mv /tmp/key_${env}.json /data/var;rm -rf /tmp/key_${env}.json 2>/dev/null'\""
    pid=`ssh ${user}@${gk} "ssh $host \"sudo su -c 'cat /data/var/start_${layer}.pid'\""`
    check=`ssh ${user}@${gk} "ssh $host \"sudo su -c 'kill -0 $pid'\""`
    #if [ $? -ne 0 ];then
    #    echo "NO permission to kill process,Aborting"
    #    exit
   # fi

    case "${layer_temp}" in

        fe)
            echo "layer FE."
            restart_fell
            ;;
        ll)
            echo "layer LL."
            restart_fell
            ;;
        dl)
            echo "layer DL."
            restart_dl
            ;;
        *)
            echo "Undefined layer."

   esac

    echo "Restarted ${host},${layer}"
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
done