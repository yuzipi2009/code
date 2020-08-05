#!/usr/bin/env bash

## By xiao.yu@kaiostech.com on 2018-10-28

## This script is used for deploying Kai-Cloud all-in-one in HK DC


# define the path
rel_dir=`dirname $0`
curr_dir=`cd $rel_dir;pwd`
abs_dir=${curr_dir}

repository_dir="/data/tools/repository"
script_dir="/data/tools/scripts"
archive_dir="/data/tools/archives"
host_record=`cat ${abs_dir}/host_list.txt`


user_list=(
 zookeeper
 tomcat
 minio
 nginx
 cassandra
 seaweedfs
 hbase
 hadoop
 cumulis
 haproxy
 nats
 redis
 autopush
)

dependency_list=(
 ius-release.rpm
 lua53u lua53u-devel
 pcre.x86_64 pcre2.x86_64
 psmisc
 bind-utils
 bzip2
)

resource=(
all-in-one*.tar.bz2
empowerthings.tar.bz2
work.tar.bz2
letsencrypt*.tar.bz2
bashrc*
hosts
cassandra_data.cql
keys.json
env_install.sh
)

## main function: loop host list execute installation.

for record in ${host_record}
    do
        ## 1.create directory and copy empowerthings package
        ip=`echo $record|awk -F "," '{print $1}'`
        host=`echo $record|awk -F "," '{print $2}'`


        echo -e "[INFO] ######################Start $ip to deploy on ${host}##################\n"
        echo  "start to clean data directory"
        ssh $ip "sudo su -c 'sudo rm -rf /data/*' && echo "[INFO] Clean data/ ok""
        sleep 2

        echo  "start to mkdir directory"
        ssh $ip "sudo su -c 'mkdir -p ${repository_dir}' && echo "[INFO]diretory ${repository_dir} is created""
        sleep 2

        echo -e "[INFO] start to change the permission of /data\n"
        ssh $ip "sudo su -c 'chmod a+w /data' && echo "[INFO] Permission of \/data is changed" || echo "[ERROR] change permission failed""
        sleep 2

        echo "[INFO] Start to scp empowerthing"
        for file in ${resource[*]};do
        scp ${archive_dir}/${file} ${ip}:/data
        done

        echo "[INFO] Files are copied to the repository directory"|| \
        {
        echo "[ERROR] happens while creating directory or copy files";exit 1
        }

        sleep 2

        echo "[INFO] Start to install killall"
        ssh $ip "sudo yum install -y psmisc && echo "psmisc installed""


        echo "[INFO] Start to install bz2"
        ssh $ip "sudo killall -9 yum;sudo yum install -y bzip2 && echo "bz2 installed""

        echo "[INFO] Start to put keys.json"
        ssh $ip "sudo rm /data/keys.json ${repository_dir}/keys && sudo mkdir ${repository_dir}/empowerthings/keys/ && cd ${repository_dir}/empowerthings/keys/ && sudo ln -s ../../keys/keys.json"
        [ $? -eq 0 ] && echo "put key.json OK " || {
       echo "[Error] put keys,json failed"
       exit
       }

        ## 2.extract package (all-in-one + work)
        echo -e "[INFO] Start to extract package all in one, please wait for about 1 minute....\n"

        ssh $ip "sudo tar -xjf /data/all-in-one*.tar.bz2 -C /data" && echo "[INFO] Package "all-in-one*.tar.bz2" extraction complete!"||
        {
        echo "[ERROR]Package "all-in-one*.tar.bz2" extraction failed, Aboring";exit 2
        }

        echo -e "[INFO] Start to extract empowerthing...\n"
        ssh $ip "sudo tar -xjf /data/empowerthings.tar.bz2 -C /data/tools/repository && echo "[INFO] Package empowerthings.tar.bz2 extraction complete!"|| \
        {
        echo "[ERROR]Package empowerthings.tar.bz2 extraction failed, Aboring";exit 2
        }"

        sleep 2

        echo -e "[INFO] Start to extract package work...\n"
        ssh $ip "tar -xjf /data/work.tar.bz2 -C ~/ && echo "[INFO] Package work.tar.bz2 extraction complete!"|| \
        {
        echo "[ERROR]Package work.tar.bz2 extraction failed, Aboring";exit 2
        }"

        sleep 2

        ## 3.invoke script env_install.sh to install dependency and tool enviroment
        echo "[INFO]start to install the enviroment before deployment..."
        ssh $ip " sh /data/env_install.sh > env_deploy.log && echo "[INFO] Enviroment prepare complete!"||{

        echo "[ERROR]Enviroment prepare failed, Aboring";exit 3
         }"

        sleep 2

        ## 4.chown belongings of directory
        echo "[INFO] Start to set the belongings of main directory..."
        ssh $ip "sudo su -c 'chown -R cumulis:cumulis ${repository_dir}/empowerthings && chown -R root:root ${repository_dir}/empowerthings-0.* \
        && echo "Change directory belongings complete!" || {
       echo "[ERROR]Change directory belongings failed, Aboring";exit 4
         }'"

       sleep 2

       ## pre-check before execute script
       ## 1.check if the modules have already been running.
        echo -e "[INFO] Start to check the status of main modules\n"
        process=`ssh $ip "ps -ef |grep -E \"nats|cumulis|cassandra|minio|redis|nginx|haproxy\" |grep -v \"grep\""`
        pid_num=`echo "$process"|wc -l`
       # echo "pid_num is $pid_num"
        pid_list=`echo "$process"|awk '{print $2}'`
       # echo "pid_list is $pid_list"

        if [ "${pid_num}" -ne 0 ];then
        echo "${pid_num} processes are running:"
        echo "${process}"

       ## how to deal with these process
        echo -e "Input "1" to kill these process \ninput "2" stop cloud firstly \ninput "3" to startup cloud anyway\n"

        sleep 2

        read -p "Input your choice:" choice

        case "${choice}" in

        1)
        for pid in ${pid_list};do
           ssh $ip "sudo kill -9 ${pid}"
           sleep 1
           echo "${pid} is killed"
        done
        pid_num=`ssh $ip "ps -ef |grep -E \"nats|cumulis|cassandra|minio|redis|nginx|haproxy\" |grep -v \"grep\"|wc -l"`
        echo -e "[INFO] Check again:\n${pid_num} processes is running now"
        ;;

        2)
        echo "stop cloud in 2 seconds"
        ssh $ip "sudo sh ${script_dir}/stop-all.sh 1>cloud_deploy.log 2>&1 && echo "Stop cloud successfully"||echo "[Error]Stop cloud failed"
        pid_num=`ssh $ip "ps -ef |grep -E \"nats|cumulis|cassandra|minio|redis|nginx|haproxy\" |grep -v \"grep\"|wc -l"`
        echo -e "[INFO] Check again:\n${pid_num} processes is running now""
        ;;

        3) echo "Startup cloud anyway"
        ;;

        *) echo "input invalid"; exit 6
        ;;

        esac

      else
      echo "[INFO] No processes is ruuning, will startup clound in 2 seconds"
      fi

      sleep 5

      ## Start Cloud
      echo -e "[INFO] Start to startup the clound\n"

      ssh $ip "sudo sh ${script_dir}/start-all.sh 1>>cloud_deploy.log 2>&1 && echo "Startup cloud successfully"||echo "[Error]Startup cloud failed""

done
