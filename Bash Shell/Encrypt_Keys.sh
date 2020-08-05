#!/bin/bash

current_dir=`dirname $0`
res_dir=`cd ${current_dir} && pwd`
abs_dir=${res_dir}
user="iot-user"
prod_gk="34.228.28.86"
prod_cass="172.31.4.248"
env="kaicloud"
cass_bin="/data/tools/repository/apache-cassandra/bin"
today=`date "+%Y-%m-%d_%H:%M"`
secret="Pz3BFM4nv0uHm8hrLzJEcPV8X3eInEUpmNzl7lIF0w"

:<<!
#Get service table
ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/service.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.service (id,name,restricted_access) to '/tmp/service.csv' with null='<null>' \\\\\\\" && chmod 755 /tmp/service.csv \\\"\""

# Copy to GK5
[[ $? -eq 0 ]] && ssh ${user}@${prod_gk} "rm -rf /tmp/service.csv; scp ${prod_cass}:/tmp/service.csv /tmp" || { echo "Copy service from cassandra failed, Aborting";exit;}

# Copy to local
[[ $? -eq 0 ]] && rm -rf service.csv; scp ${user}@${prod_gk}:/tmp/service.csv ./ && echo "Fetch service.csv to local.. OK"|| { echo "Copy service from K5-GK failed, Aborting";exit;}
!
#Change data format

OLD_IFS=$IFS
IFS=$'\n'

cat /dev/null > source_key.csv
for line in `cat /tmp/service.csv`;do
    keyid=`echo $line|awk -F, '{print $1}'`
    service=`echo $line|awk -F, '{print $2}'|awk '{print $(NF-1),$NF}'|sed 's/ /_/g'`
    project_name=`echo $line|awk -F, '{print $2}'|awk '{$NF=null;$(NF-1)=null;print $0}'|sed 's/ /_/g'|sed 's/_\+$//g'`
    key=`echo $line|grep -Po "key:\s+\S+"|awk -F\' '{print $2}'`
    key_s=${#key}

    if [ ${key_s} -lt 10 ]||[ "x" == "${service}x" ]||[ "x" == "${project_name}x" ];then
	continue
    fi
    if [ ${keyid} == "np9tbBL2sZPU07OUWHMy" ];then
	service="App_Store"
        project_name="TCT_GoFlip2"
    fi
    if [ ${keyid} == "iOaA5BZYDv8hlo_h3oaT" ];then
        service="Restricted_Bearer_Token"
        project_name="TCT_GoFlip2"
    fi

    echo -n "$project_name " >> source_key.csv
    echo -n "$service " >> source_key.csv
    echo -n "$keyid " >> source_key.csv
    echo "$key" >> source_key.csv
done

rm -rf encrypt_key.csv
cp -a source_key.csv encrypt_key.csv

#Decode the key
for line in `cat encrypt_key.csv`;do
    key=`echo $line|awk '{print $NF}'`
    if [[ ! $key  =~ ^[0-9a-zA-Z] ]];then
        hash_key=`printf '\'"$key"|shasum -a 256|awk '{print $1}'`
    else
	hash_key=`printf $key|shasum -a 256|awk '{print $1}'`
    fi

    #enycrypt_key=`echo $key|openssl aes-128-cbc -k ${secret} -base64`
    echo "keyis $key-------> $hash_key"
    sed -i "s@$key@$hash_key@g" ./encrypt_key.csv
    #decrypt_key=`echo $enycrypt_key|openssl aes-128-cbc -d -k ${secret} -base64`
    #if [ "$key" != "$decrypt_key" ];then
    #    echo "Key NOT MATCH!!!!!!!!!!!!!!!"
    #fi
done
IFS=$OLD_IFS
