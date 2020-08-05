#!/bin/bash

# this script is used to copy ha1 configuration file to ha2 and then reload ha2
# this script should be run as kai-user

rela_dir=`dirname $0`
haproxy_dir=`cd ${rela_dir}/../; pwd`

ha2_ip=10.81.74.44


#ssh test
ssh ${ha2_ip} -o ConnectTimeout=3 "exit"

[ $? -eq 0 ] || {
echo "[Error]ssh test failed, Aborting"
exit
}
#copy file + reload
scp ${haproxy_dir}/etc/configuration.conf ${ha2_ip}:./ && \
ssh ${ha2_ip} "sudo mv ${haproxy_dir}/etc/configuration.conf ${haproxy_dir}/etc/configuration.conf_`date +%Y%m%d` && \
sudo mv ./configuration.conf ${haproxy_dir}/etc/ && \
cd ${haproxy_dir} && \
sudo sbin/reload-haproxy.sh"
[ $? -eq 0 ] || {
echo "[Error]copy or reload failed,Aborting"
exit
}

#check haproxy.out
result=`ssh ${ha2_ip} "sudo grep -i 'error' ${haproxy_dir}/var/logs/haproxy.out"`

if [ "${result}x" = "x" ];then
        echo "haproxy-a-002 reloaded successfully"
    else
        echo -e "haproxy-a-002 reloaded with error, please check:\n"${result}" "
fi