#!/bin/bash

readonly red=$(tput bold; tput setaf 1)
readonly green=$(tput bold; tput setaf 2)
readonly blue=$(tput bold; tput setaf 4)
readonly reset=$(tput sgr0)

export GOLANG_HOME=/data/tools/repository/go/
export GOROOT=${GOLANG_HOME}
export JAVA_HOME=/data/tools/repository/java

# Maven environment variables
export M2_HOME=/data/tools/repository/apache-maven
export M2=${M2_HOME}/bin
export MAVEN_OPTS="-Xms128m -Xmx256m"
export PATH=${JAVA_HOME}/jre/bin:${JAVA_HOME}/bin:${PATH}:${M2}:${GOLANG_HOME}/bin

work_dir=/home/yuxiao/Desktop/deploy_production
check_out=/home/yuxiao/Desktop/deploy_production/empowerthing_check_out


repo_dir=/data/tools/repository
remote_user="kai-user"
gk5=34.228.28.86


fe=(
172.31.10.219
172.31.33.1
172.31.18.12
)

ll=(
172.31.11.180
172.31.31.234
172.31.44.123
)

dl=(
172.31.15.221
172.31.41.139
172.31.19.159
)


all_node="${fe[*]} ${ll[*]} ${dl[*]}"
step () {
   echo "============================================="
   echo "    $1"
   echo "============================================="
   echo
}



step "1 - Check_key"

if [ -f "${work_dir}/k5.json" ];then
	echo "Key is Here"
else
	echo "Didn't find keys.json, Aborting"
	exit
fi



step "2 - Copy_Key_To_GK"

scp ${work_dir}/k5.json ${remote_user}@${gk5}:/tmp
[ $? -eq 0 ] && echo "copied key to GK successfully" || {
echo "copy key to GK failed..aborting" 
exit
}

for node in ${all_node};do
    ssh ${remote_user}@${gk5} "scp /tmp/k5.json ${node}:/tmp && ssh ${node} \"sudo su -c \\\"mv /tmp/k5.json ${repo_dir} && chown  cumulis: ${repo_dir}/k5.json \\\"\""
    [ $? -eq 0 ] && echo "${green}Copied key to $node and .....OK" && echo "${reset}" || {
    echo "${red}Copied key to $host .....Failed, Aborting..." && echo "${reset}"
    exit
    }
done

step "4 - Delete key from GK"

ssh ${remote_user}@${gk5} "rm -rf /tmp/k5.json"
[ $? -eq 0 ] && echo "Delete key successfully" || echo "Delete key failed..aborting" 

echo "copy keys.json to production complete"
