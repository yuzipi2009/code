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

# comment out below lines to save time
:<<!
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
!


# Main loop

sed -i 's/ //g' ${summary}
for line in `grep -i  ${app_id} ${summary}`;do
 	app_id=`echo ${line}|awk -F, '{print $1}'`
        app_name=`echo ${line}|sed 's/{.*}/null/g'|awk -F ',' '{print $(NF-15)}'` 
	if [ "${app_id}" == "1pbIfwzCFmZM6rwzEVvA" ];then
                app_name="Maps"
            elif [ "${app_id}" == "W7QWTY9dVXxpsJ2whbxk" ];then
                app_name="Twitter"
            elif [ "${app_id}" == "6x6P4Ap7oCIzOW10hBpm" ];then
                app_name="YouTube"
            elif [ "${app_id}" == "oRD8oeYmeYg4fLIwkQPH" ];then
                app_name="Facebook"
            elif [ "${app_id}" == "vAQ_cypuhw7nt8cjRaHP" ];then
                app_name="Life"
            elif [ "${app_id}" == "ZL1czhKqL8sTAqZslZhA" ];then
                developer="JOYO_TECHNOLOG.LTD"
            elif [ "${app_id}" == "H27kQL2sVemarCQnFrF3" ];then
                developer="jiji"
            elif [ "${app_id}" == "-5yTeRojIPDKDsN5CxV_" ];then
                app_name="Shooting Star"
            elif [ "${app_id}" == "E6X0Dkol4yxRFMwlyByZ" ];then
                app_name="Bubble Shooter"           
            fi

	# Get account_id
	ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select * from ${KEYSPACE}.app_summary_by_account where id='${app_id}' ALLOW FILTERING ;\\\\\\\" \\\"\"" > ${tmp_dir}/account.log


	NB_LINES=`wc -l ${tmp_dir}/account.log | awk '{ print $1 }'`
	let NB_RECORDS="$NB_LINES-5"
	let NB_LAST_LINES="$NB_LINES-3"
	record=`tail -n $NB_LAST_LINES ${tmp_dir}/account.log | head -n $NB_RECORDS|sed 's/ //g'`

	cd ${hawk} 

	for line2 in `echo ${record}`;do
		uid=`echo ${line2}|awk -F\| '{print $1}'`
        	bin/test_hawk -c jwt/prod_token.json GET https://api.kaiostech.com/v3.0/accounts/${uid} > ${tmp_dir}/out.txt 2>${tmp_dir}/err.txt
        	expire=`grep 'Token expired' ${tmp_dir}/out.txt`
        	err=`grep '200 OK' ${tmp_dir}/err.txt`
        if [ "${expire}x" != "x" ];then
		bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.kaiostech.com/v3.0/tokens > jwt/prod_token.json 2>/dev/null 
		#run again
		bin/test_hawk -c jwt/prod_token.json GET https://api.kaiostech.com/v3.0/accounts/${uid} > ${tmp_dir}/out.txt 2>${tmp_dir}/err.txt
		elif [ "${err}x" != "x" ];then
			echo "The uploader of ${app_name} is:"
        		jq '.[]' ${tmp_dir}/out.txt|grep -E -w 'first_name|login'
                        echo -e
		else
			echo "error!"
		fi
	done	
done
#rm -rf ${tmp_dir}

