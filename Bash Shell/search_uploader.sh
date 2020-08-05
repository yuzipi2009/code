#!/bin/bash

# This script takes 3 parameters:
# env: test or stage
# app id: the app id to modify
# recommeded index: the recommended index to set for the provided app id
#
# It will search all app_version/app_for_device/app2 tables of this app and set its recommended_index to the desired value.
#


thedate=`date +'%Y%m%d'`
thetime=`date +'%H%M%S'`
tmp_dir=`mktemp -d`
summary="/home/kai-user/app_summary.csv"


# Scheduling a delete of the temporary directory in 10 min.
echo "rm -Rf $tmp_dir" | at -m now +10 minute 2>/dev/null

tmp_dir=`mktemp -d`
CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"
hawk="/data/bin/hawk"
app_id=$1

user=iot-user
gk=34.228.28.86
cass=172.31.35.124
KEYSPACE=kaicloud

if [ "x" = "x$app_id" ]; then
        echo "Failed"
        echo "[ERROR] Missing mandatory parameters. Aborting ...."
        echo
	echo "Usage: $0  \${app_id}"
	exit 1
fi


#Judge CQLSH
ssh ${user}@${gk} "ssh ${cass} \"test -e \\\"$CQLSH\\\"\""|| { echo "Failed" && echo "[ERROR] $CQLSH doesn't exist! Aborting ..." && exit 2;}


# Testing connectivity to Cassandra
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"desc keyspaces\\\\\\\" \\\"\"" >${tmp_dir}/out.log
if [ $? -ne 0 ]; then
    echo "Failed"
    echo >&2 "[ERROR] Failed to connect to Cassandra. Error message follow:"
    cat ${tmp_dir}/error.log
    exit 3
fi



# Get app_id
app_id=`grep -i  ${app_id} ${summary}|awk -F, '{print $1}'`

# Get account_id
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select * from ${KEYSPACE}.app_summary_by_account where id='${app_id}' ALLOW FILTERING ;\\\\\\\" \\\"\"" > ${tmp_dir}/account.log


NB_LINES=`wc -l ${tmp_dir}/account.log | awk '{ print $1 }'`
let NB_RECORDS="$NB_LINES-5"
let NB_LAST_LINES="$NB_LINES-3"
record=`tail -n $NB_LAST_LINES ${tmp_dir}/account.log | head -n $NB_RECORDS|sed 's/ //g'`

cd ${hawk}

for line in `echo ${record}`;do
	uid=`echo ${line}|awk -F\| '{print $1}'`
        bin/test_hawk -c jwt/prod_token.json GET https://api.kaiostech.com/v3.0/accounts/${uid} > ${tmp_dir}/out.txt 2>${tmp_dir}/err.txt
        expire=`grep 'Token expired' ${tmp_dir}/out.txt`
        err=`grep '200 OK' ${tmp_dir}/err.txt`
        if [ "${expire}x" != "x" ];then
		bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.kaiostech.com/v3.0/tokens > jwt/prod_token.json 2>/dev/null
	elif [ "${err}x" != "x" ];then
        	jq '.[]' ${tmp_dir}/out.txt|grep -E -w 'first_name|login'
	fi
done

#rm -rf ${tmp_dir}
