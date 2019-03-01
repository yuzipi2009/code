#!/bin/bash

## By xiao.yu@kaiostech.com on 2018-10-28

## This script is used for deploying Kai-Cloud all-in-one in HK DC


# define the path
rel_dir=`dirname $0`
curr_dir=`cd $rel_dir;pwd`
abs_dir=${curr_dir}

repository_dir="/data/tools/repository"
script_dir="/data/tools/scripts"

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
 lsof
)


# functon1: prepare the enviroment
function env_prepare()
{


# useradd
echo -e "[INFO] start to add user..."
 for user in ${user_list[*]};do
    sudo useradd $user
    echo "${user} is added."
    sleep 1
done

sleep 2

echo "[INFO] Start to Install Package Dependency"

# install dependency and tools

sudo killall -9 yum

yum_check=`sudo yum repolist |awk '/repolist/{print $0}'|awk '{print $2}'|sed 's/,//'`
[ ${yum_check} = "0" ] && echo "[Error]yum is unuseable, Aborting" && exit 7|| echo -e "[INFO] yum is avaliable!\n"

sleep 2

sudo yum install -y wget
wget https://centos7.iuscommunity.org/ius-release.rpm 2

for package in ${dependency_list[*]};do
    echo -e "[INFO] Start to Install $package\n"
    sudo yum install -y ${package} |tail -n 2
   sleep 2
done


# replace hosts .bashrx of root and cumulis and copy letsencrypt files to /etc

echo "[INFO] Start to replace hosts"

sudo mv /etc/hosts /etc/hosts.`date +%Y%m%d`
sudo cp /data/hosts /etc && \
echo "hosts is replaced" && sleep 1

echo "[INFO] Start to replace bashrc"

sudo mv /root/.bashrc /root/.bashrc.`date +%Y%m%d`
sudo cp /data/bashrc_root /root/.bashrc && \
sudo su -c "source /root/.bashrc" && echo "bashrc of root is resourced" && sleep 1

sudo mv /home/cumulis/.bashrc /home/cumulis/.bashrc.`date +%Y%m%d` && sudo cp /data/bashrc_cumulis /home/cumulis/.bashrc && \
sudo su -c "source /home/cumulis/.bashrc" && echo "bashrc of cumulis is sourced" && sleep 1


if [ -f ~/.bashrc_functions ]; then
mv ~/.bashrc_functions ~/.bashrc_functions.`date +%Y%m%d`
fi
cp /data/bashrc_functions ~/.bashrc_functions && \
#source /home/kai-user/.bashrc_functions
echo "bashrc_function for kai-user is replaced"

sudo mv ~/.bashrc ~/.bashrc.`date +%Y%m%d` && cp /data/bashrc_kai-user ~/.bashrc && \
source ~/.bashrc && echo "bashrc of kai-user is sourced"


sudo mv /home/tomcat/.bashrc /home/tomcat/.bashrc.`date +%Y%m%d`
sudo cp /data/bashrc_tomcat /home/tomcat/.bashrc && \
sudo su -c "source /home/tomcat/.bashrc" && echo "bashrc of tomcat is resourced"

sudo chown -R cumulis: /data/tools/repository/empowerthings
sudo chown -R root: /data/tools/repository/empowerthings-0.*

sleep 3

echo -e "[INFO] Start to extact lensencrypt file to [/etc]"
sleep 2

sudo tar -xjf /data/letsencrypt-20180914.tar.bz2 -C /etc && \
echo "[INFO] bashrc and letsencrypt is replaced successfully" && \
echo "ENV istalled successfully!" && exit 0|| \
echo "[ERROR] happens while replacing bashrc, Aborting"
exit 10

#set cassandra data
/data/tools/repository/apache-cassandra/bin/cqlsh -f /data/cassandra_data.cql
[ $? -eq 0 ] && echo "cassandra data set ok" || echo "[ERROR] cassandra data set failed"
}

env_prepare