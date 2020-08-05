#!/usr/bin/env bash
current_dir=`dirname $0`
res_dir=`cd ${current_dir} && pwd`
abs_dir=${res_dir}
hser="iot-user"
prod_gk="34.228.28.86"
prod_cass="172.31.3.192"
env="kaicloud"
cass_bin="/data/tools/repository/apache-cassandra/bin"

:<<!
ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/cass_curef.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.curef to '/tmp/cass_curef.csv' with header=true and null='<null>' \\\\\\\" && chmod 755 /tmp/cass_curef.csv \\\"\""

[[ $? -eq 0 ]] && ssh ${user}@${prod_gk} "rm -rf /tmp/cass_curef.csv && scp ${prod_cass}:/tmp/cass_curef.csv /tmp" || { echo "Copy curef from cassandra failed, Aborting";exit;}

[[ $? -eq 0 ]] && rm -rf ${abs_dir}/cass_curef.csv && scp ${user}@${prod_gk}:/tmp/cass_curef.csv ${abs_dir} && echo "Fetch cass_curef.csv to local.. OK"|| { echo "Copy curef from K5-GK failed, Aborting";exit;}  # now you have the cassandra cass_curef.csv in /home/yuxiao/De:sktop/change_cu
!
if [ ! -f fota_cu.xls ];then
        echo "didn't find fota_cu.xls, Aborting.."
        exit 2
fi
#delete the first line
grep -v -w 'CU' fota_cu.xls > fota_cu.txt
sed '1d' cass_curef.csv |sed 's/ //g' > cass_curef.txt

#run change cu.sh
${abs_dir}/cu_change.sh cass_curef.txt fota_cu.txt
# If the top steps run successfully, the new_cu.txt will be saved in ${abs_dir}/`date +%Y%m%d` directory

if [ ! -f new_cu.txt ];then
	echo "didn't find new_cu.txt file, please check the return of cu_change script, Aborting.."
        exit 3
fi

#run post cu api by loop new_cu.txt
## create cu json fie
mkdir ${abs_dir}/`date +%Y%m%d`  #this dir is used to save new_curef
cu_repository=$(cd ${abs_dir}/`date +%Y%m%d`;pwd)
i=0
for new_cu in `cat new_cu.txt`;do
    let i=i+1
    echo  "{"  > ${cu_repository}/new_curef${i}.json
    echo  "   \"curef\": \"${new_cu}\"," >> ${cu_repository}/new_curef${i}.json
    echo  "   \"description\": \"INTER_TEST\"" >> ${cu_repository}/new_curef${i}.json
    echo "}" >> ${cu_repository}/new_curef${i}.json

    if [ ! -f ${cu_repository}/new_curef1.json ];then
        echo "didn't find new_cu.txt file, no new cu need to be posted  Aborting.."
        exit 4
    else
	echo "new curef files are generate"
    fi
done

#statistic
num=`wc -l new_cu.txt`
all_new_cu=`cat new_cu.txt`
echo "========<${num}> curef are found :========"
echo "${all_new_cu}"


+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

