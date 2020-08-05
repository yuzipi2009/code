#!/bin/bash

readonly red=$(tput bold; tput setaf 1)
readonly green=$(tput bold; tput setaf 2)
readonly blue=$(tput bold; tput setaf 4)
readonly reset=$(tput sgr0)

rel_dir=`dirname $0`
current_dir=`cd ${rel_dir}; pwd`
emp_dir=/data/tools/repository/empowerthings
repo_dir=/data/tools/repository
remote_user="kai-user"
version=$1

zonea=(
fe3-172.31.10.219
ll3-172.31.11.180
dl3-172.31.15.221
)

zoneb=(
fe3-172.31.18.12
ll3-172.31.31.234
dl3-172.31.19.159
)

zonec=(
fe3-172.31.33.1
ll3-172.31.44.123
dl3-172.31.41.139
)




all_node="${zonea[*]} ${zoneb[*]} ${zonec[*]}"
step () {
   echo "============================================="
   echo "    $1"
   echo "============================================="
   echo
}

step "1 - Copy_Key_To_Server"

#Check key

if [ ! -f ${current_dir}/k5.json ] || [ "${version}x" == "x" ];then
	echo "Did not find key or miss version as 1st argument, Aborting"
    exit 6
fi

for node in ${all_node};do
    layer=`echo $node|awk -F '-' '{print $1}'`
    ip=`echo $node|awk -F '-' '{print $2}'`
    scp ${current_dir}/k5.json ${ip}:/tmp && ssh ${ip} "sudo su -c 'mv /tmp/k5.json ${emp_dir} && chown cumulis: ${emp_dir}/k5.json'"
    [ $? -eq 0 ] && echo "${green}Copied key to $node successfully" && echo "${reset}" || {
    echo "${red}Copied key to $host .....Failed, Aborting..." && echo "${reset}"
    exit
    }
done


step "2 - Stop and Start Zone A ->B ->C"

for node in ${all_node};do
    layer=`echo $node|awk -F '-' '{print $1}'`
    ip=`echo $node|awk -F '-' '{print $2}'`
    echo -n "${green}Working on $node ....." && echo -n "${reset}"

    # check if key is ready
    k=`ssh ${ip} "sudo su - cumulis -c 'cat ${emp_dir}/k5.json'"`
    #echo -e "key is \n, $k"
    if [ $? -ne 0 ] || [ "${k}x" == "x" ];then
        echo -e "${red}\nCheck Key on ${ip} failed, empty key or no key, Aborting.." && echo "${reset}"
        exit2
    fi

    #stop service -> recreate link -> start service
    ssh ${ip} "sudo su - cumulis -c ' cd ${emp_dir} && bin/stop_service.sh ${layer}|head -2 && rm -rf old; mv bin old && ln -s $repo_dir/empowerthings-$version/bin ./ && bin/start_service.sh ${layer} ./k5.json && ps -ef|grep $layer|grep -v 'grep'|head -1'"
    if [ $? -ne 0 ];then
        echo -e "${red}\nThere is error happened when [stop service -> recreate link -> start service]\n Please check ${ip},Aborting.." && echo "${reset}"
        exit 3
    fi
    echo "${green}OK" && echo "${reset}"
done

echo "${blue}Deploy Finished" && echo "${reset}"