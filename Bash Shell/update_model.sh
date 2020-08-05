#!/usr/bin/env bash
#!/bin/bash

current_dir=`dirname $0`
res_dir=`cd ${current_dir} && pwd`
abs_dir=${res_dir}
user="iot-user"
prod_gk="34.228.28.86"
prod_cass="172.31.4.248"
env="kaicloud"
cass_bin="/data/tools/repository/apache-cassandra/bin"

# delete some exsiting files  which will be generated in the following script firstly
# to avoid some descriptions
:<<!
# Fetch fota cu file from DM
ssh iot-user@34.195.102.186 "ssh 172.31.12.160 \"sudo su -c \\\"/data/tools/bin/mysql gotu -uroot -pAdmin01ME! -e 'select productclass_curefregexp as 'CU',productfamily.productfamily_brand_model as description from productclass LEFT JOIN fileset on productclass_fileset_id = fileset_id LEFT JOIN productfamily on fileset_productfamily_id = productfamily_id where productclass_isactive = 1 and productfamily_isactive=1' \\\" \"" > fota.csv

echo "fetched fota.csv"

# Fetch store tables
ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/cass_curef.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.curef to '/tmp/cass_curef.csv' with header=true and null='<null>' \\\\\\\" && chmod 755 /tmp/cass_curef.csv \\\"\""

[[ $? -eq 0 ]] && ssh ${user}@${prod_gk} "rm -rf /tmp/cass_curef.csv && scp ${prod_cass}:/tmp/cass_curef.csv /tmp" || { echo "Copy curef from cassandra failed, Aborting";exit;}

[[ $? -eq 0 ]] && rm -rf ${abs_dir}/cass_curef.csv && scp ${user}@${prod_gk}:/tmp/cass_curef.csv ${abs_dir} && echo "Fetch cass_curef.csv to local.. OK"|| { echo "Copy curef from K5-GK failed, Aborting";exit;}  # now you have the cassandra cass_curef.csv in /home/yuxiao/De:sktop/change_cu

#==========================================================================================================
# now we have fota.csv and cass_curef.csv

sed '1d' cass_curef.csv |sed 's/ //g' > cass.txt
#delete the first line, and remove the space in description for both fota and cassandra cu file
egrep -v -w 'description|NULL' fota.csv |sed 's/ //g'|sed 's/\t/,/g'> fota.txt

#==============================================================================
# now we have fota.txt and cass.txt
!

declare -A cu2id
declare -A cu2cass_model
declare -A cu2fota_model

for line in `cat cass.txt`
do
        id=`echo $line | awk -F, '{print $1}'`
        cu=`echo $line | awk -F, '{print $2}'`
        model_cass=`echo $line | awk -F, '{print $3}'`
        match_fota=`grep ${cu} fota.txt`
        if [ "${match_fota}x" == "x" ];then   #means the cu is in store but not in fota, should delete it.
        	echo "this cu is in store but not it fota : ${cu}"
        else
 		cu2cass_model[$cu]=$model_cass
        fi
done  #now we get a cu2cass_model dic

rm -rf ./fixed_model.txt 2>/dev/null

for line in `cat fota.txt`
do

     curef=`echo ${line}|awk -F, '{print $1}'`
     model_fota=`echo ${line}|awk -F, '{print $2}'`
     cu2fota_model[$curef]=$model_fota
     model_cass=${cu2cass_model[$curef]}
     #echo "${model_cass} ===> ${model_fota}"
     if [ "${model_cass}" != "${model_fota}" ];then  #compare fota_model and cass_model
     	echo "${curef}'s model should be ${model_fota}, not ${model_cass}"
     	echo "${curef},${model_fota}" >> fixed_model.txt #fixed_model.txt is the final file which contains correct "cu,model" pair"
     fi
done

====================================================================
#          update.sh
=====================================================================

#!/bin/sh

readonly red=$(tput bold; tput setaf 1)
readonly green=$(tput bold; tput setaf 2)
readonly reset=$(tput sgr0)
today=`date +%Y-%m-%d`

echo -e "==========${today}=========\n" >> var/api.log
echo -e "==========${today}=========\n" >> var/result.log
#=============================================================
./bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.kaiostech.com/v3.0/tokens >jwt/prod_token.json

for line in `cat ./fixed_model.txt`;do
	cu=`echo ${line}|awk -F, '{print $1}'`
        model=`echo ${line}|awk -F, '{print $2}'`

       ./bin/test_hawk -H "Content-Type: application/json" -c ./jwt/prod_token.json POST https://api.kaiostech.com/v3.0/curef -d '{"curef":"'${cu}'","description":"'${model}'"}'>> var/api.log

	[ $? -eq 0 ] && echo "change ${green}${cu} model to ${red}${model}" |tee -a  var/result.log  && echo "${reset}"
       sleep 1
done

rm -rf test-hawk.log.*