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
version=$1


repo_dir=/data/tools/repository
remote_user="iot-user"
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

#:<<!
step "1 - Build"

if [ "x${version}" == "x" ];then
    echo "Please Specify the version, Aborting.."
    exit
fi

cd ${work_dir} && rm -rf empowerthing_check_out 

git clone git@git.kaiostech.com:cloud/empowerthings.git ${check_out}
cd "${check_out}" && git checkout ${version} || {
echo "check out failed, Aborting..."
exit
}

make clean && make deploy || {
echo "make failed, Aborting..."
exit
}

[ $? -eq 0 ] || {
echo "complile empowerthings-${Tags} failed"
exit
}

#!

step "2 - Check_Connectivity"

for node in ${all_node};do    
    host=`ssh ${remote_user}@${gk5} "ssh ${node} "sudo su -c 'hostname' ""`
    [ $? -eq 0 ] && echo "${green}$host .....OK" && echo "${reset}" || {
    echo "${red}$host .....Failed, Aborting..." && echo "${reset}"
    exit
    }
done

step "3 - Copy_Extract_Package"

cd "${check_out}" && scp empowerthings-${version}.tar.bz2 ${remote_user}@${gk5}:/tmp
[ $? -eq 0 ] && echo "copied package to GK successfully" || {
echo "copy package to GK failed..aborting" 
exit
}

for node in ${all_node};do
    ssh ${remote_user}@${gk5} "scp /tmp/empowerthings-${version}.tar.bz2  ${node}:/tmp && ssh ${node} \"sudo su -c \\\"mv /tmp/empowerthings-${version}.tar.bz2 ${repo_dir} && cd ${repo_dir} && tar -xjf ${repo_dir}/empowerthings-${version}.tar.bz2 && chown -R root: ${repo_dir}/empowerthings-${version} && rm -rf ${repo_dir}/empowerthings-${version}.tar.bz2 \\\"\""
    [ $? -eq 0 ] && echo "${green}Copied package to $node and extract.....OK" && echo "${reset}" || {
    echo "${red}Copied package to $host or extract.....Failed, Aborting..." && echo "${reset}"
    exit
    }
done

echo "${green} Copy empowerthings-$version to production complete" && echo "${reset}"
