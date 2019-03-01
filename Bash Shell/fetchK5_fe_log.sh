iot-user@k5-na2-gk-a-001 ~/bin > more k5_fetch_fe_log.sh
#!/bin/bash

current_rel_dir=`dirname $0`
abs_tool_dir=`cd ${current_rel_dir}; pwd`

node_list_file="${abs_tool_dir}/k5_fe_nodes_list.txt"



# Fetching which day should be used to fetch the log. Default is yesterday if not provided.
yesterday=""
theyear=""
thedate=$1

if [ "x" = "x$thedate" ]; then
 yesterday=`date +'%Y%m%d' -d yesterday`
 theyear=`date +'%Y' -d yesterday`
else
 if [[ "$thedate" =~ ^[0-9]{8}$ ]]; then
  yesterday=$thedate
  theyear=`echo $thedate | cut -b -4`
 else
  echo "[ERROR] Wrong format for input date '$thedate'! Should be YYYYMMDD."
  exit 1
 fi
fi


if [ ! -r "${node_list_file}" ]; then
        echo "[ERROR] Node List File '${node_list_file}' cannot be read. Aborting!"
        exit 1
fi

node_list=`cat ${node_list_file}`

thedate=`date +'%Y%m%d'`
thetime=`date +'%H%M%S'`

temp_dir=`mktemp -d`

for host_record in $node_list
do
        host_ip=`echo $host_record | awk -F, '{ print $1 }'`
        host_name=`echo $host_record | awk -F, '{ print $2 }'`

        echo "--------- $host_name --- ($host_ip) ---- $yesterday ----------"
        ssh ${host_ip} "sudo su - cumulis -c 'xzgrep METRICS /data/var/logs/${yesterday}*/* >/tmp/${yesterday}-${host_name}.log'"
 scp ${host_ip}:/tmp/${yesterday}-${host_name}.log $temp_dir
        ssh ${host_ip} "sudo su - cumulis -c 'rm -f >/tmp/${yesterday}-${host_name}.log'"
 sed -i 's/^[^:]*://' $temp_dir/${yesterday}-${host_name}.log
done

cat $temp_dir/${yesterday}*.log | sort >$temp_dir/${yesterday}-full-fe.log

xz $temp_dir/${yesterday}-full-fe.log

mv $temp_dir/${yesterday}-full-fe.log.xz .

md5sum ${yesterday}-full-fe.log.xz | awk '{ print $1 }' >${yesterday}-full-fe.log.xz.md5
sha1sum ${yesterday}-full-fe.log.xz | awk '{ print $1 }' >${yesterday}-full-fe.log.xz.sha1

rm -Rf $temp_dir