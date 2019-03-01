#!/bin/bash

egrep -v 'localhost' /etc/hosts|sed 's/\s\+/,/g' > file.txt

record=`cat file.txt`

for line in ${record};do
    ip=`echo ${line}|awk -F, '{print $1}'`
    host=`echo ${line}|awk -F, '{print $2}'`
    ssh ${ip} "sed -i 3,\$d"
    [ $? -eq 0 ] && echo "cleaned jenkins pubkey from $host" || {
     echo "clean $host failed"
           break
}
done