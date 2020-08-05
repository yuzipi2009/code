#!/bin/bash

#this is used to add jenkins ip and hostname to hosts.allow file so that jenkins server can ssh to them

egrep -v 'localhost' /etc/hosts|sed 's/\s\+/,/g' > file2.txt

record=`cat file2.txt`

for line in ${record};do
    ip=`echo ${line}|awk -F, '{print $1}'`
    host=`echo ${line}|awk -F, '{print $2}'`
    ssh ${ip} "sudo sed -i '/k2-hk1-jenk-a-001/d' /etc/hosts.deny" &&
    ssh ${ip} 'sudo su -c "echo -e 'sshd: 10.81.74.174' >> /etc/hosts.allow"' &&
    ssh ${ip} 'sudo su -c "echo -e 'sshd: k2-hk1-jenk-a-001' >> /etc/hosts.allow"'
    [ $? -eq 0 ] && echo " added jenkins host to $host" || {
    echo "add jenkins host to  $host failed"
    break
}
done

rm -rf file2.txt
