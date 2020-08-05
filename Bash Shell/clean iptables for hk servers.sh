
#! /bin/bash

rel_dir=`dirname $0`
cur_dir=`cd ${rel_dir};pwd`
abs_dir=${cur_dir}

host_record=`cat host_file.txt`

[ -f host_file.txt ] && echo "file check ok" || {

echo "no host file";exit 1
}

for record in ${host_record};do
    ip=`echo ${record}|awk -F , '{print $1}'`
    host=`echo ${record}|awk -F , '{print $2}'`
    echo "clean $host now"
    ssh ${ip} -o ConnectTimeout=3 "sudo rm -rf /etc/rc.local && cd /etc && sudo ln -s rc.d/rc.local" &&
    ssh ${ip} -o ConnectTimeout=3 "sudo su -c ' \

cat > /etc/rc.d/rc.local<<EOF
#!/bin/bash
sudo iptables -F
EOF'"

    [ $? -eq 0 ] && echo "clean/add rc.local ${ip} complete" || {
    echo "${ip} error happened, aborting"
    break
    }
    data2=`ssh ${ip} -o ConnectTimeout=3 "sudo cat /etc/rc.d/rc.local"`
    echo -e "data2 is :\n${data2}"
sleep 3
done