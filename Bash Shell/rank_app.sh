#!/bin/sh

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

# Scheduling a delete of the temporary directory in 10 min.
echo "rm -Rf $tmp_dir" | at -m now +10 minute 2>/dev/null

CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"
env=$1
app_id=$2
recommended_index=$3

echo -n "[1/4] Check Arguments ...."
if [ "x" = "x$recommended_index" ]||[ "x" = "x$app_id" ]||[ "x" = "x$env" ]; then
        echo "Failed"
        echo "[ERROR] Missing mandatory parameters. Aborting ...."
        echo
	echo "Usage: $0 {env}  {app id}   {recommended_index}"
	echo "    Example. For stage whatsapp:"
	echo "    $0 stage ahLsl7Qj6mqlNCaEdKXv   1"
	exit 1
else
    echo "Pass"
fi


case  ${env} in
    test)
        user=kai-user
        gk=10.81.76.19
        cass=10.81.74.132
        KEYSPACE=kaicloud_test
        ;;

    stage)
        user=iot-user
        gk=34.193.231.19
        cass=172.31.13.22
        KEYSPACE=kaicloud_stage
        ;;
    *)
        echo "env must be stage or test, Aborting"
        exit
esac

#Judge CQLSH
echo -n "[2/4] Check Cqlsh...."
ssh ${user}@${gk} "ssh ${cass} \"test -e \\\"$CQLSH\\\"\"" && echo "Pass"|| { echo "Failed" && echo "[ERROR] $CQLSH doesn't exist! Aborting ..." && exit 2;}


# Testing connectivity to Cassandra

#ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin "$CQLSH\\\"\\\"\" >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "desc keyspaces"
echo -n "[3/4] Check Cassandra Connectivity...."
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"desc keyspaces\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
if [ $? -ne 0 ]; then
    echo "Failed"
    echo >&2 "[ERROR] Failed to connect to Cassandra. Error message follow:"
    cat ${tmp_dir}/error.log
    exit 3
else
    echo "Pass"
fi

# Making sure the application with the given id exists!
echo -n "[4/4] Check APP...."
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select name from ${KEYSPACE}.app_summary where id='${app_id}';\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
#$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "select name from ${KEYSPACE}.app_summary where id='${app_id}';"

if [ $? -ne 0 ]; then
    echo "Failed"
 	echo "[ERROR] Failed to execute query:"
	cat ${tmp_dir}/error.log
	exit 4
else
    echo "Pass"
fi

tail -1 ${tmp_dir}/out.log | grep >/dev/null 2>/dev/null '(0 rows)'

if [ $? -eq 0 ]; then
 	echo "[ERROR] Application with id '$app_id' not found. Aborting ..."
	exit 5
fi

tail -1 ${tmp_dir}/out.log | grep >/dev/null 2>/dev/null '(1 rows)'

if [ $? -ne 0 ]; then
        echo "[ERROR] Application with id '$app_id' has several records. Aborting ..."
        cat ${tmp_dir}/out.log
        exit 6
fi

app_name=`head -4 ${tmp_dir}/out.log | tail -1 | sed 's/ //g'`

echo "========================================================="
echo "Found application '$app_name' with id '$app_id'"

ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select id,name,recommended_index,status from ${KEYSPACE}.app_for_device where id='${app_id}';\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
#$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "select id,name,recommended_index,status from ${KEYSPACE}.app_for_device where id='${app_id}';"

tail -1 ${tmp_dir}/out.log | grep >/dev/null 2>/dev/null '(0 rows)'

if [ $? -eq 0 ]; then
        echo "[ERROR] Application with id '$app_id' cannot be found into ${KEYSPACE}.app_for_device. Aborting ..."
        cat ${tmp_dir}/out.log
        exit 6
fi

#Check app_2 table
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select id,version from ${KEYSPACE}.app_2 where id='${app_id}';\\\\\\\" \\\"\"" >${tmp_dir}/out_2.log  2>${tmp_dir}/error_2.log
#$CQLSH >${tmp_dir}/out_2.log  2>${tmp_dir}/error_2.log -e "select id,version from ${KEYSPACE}.app_2 where id='${app_id}';"
tail -1 ${tmp_dir}/out_2.log | grep >/dev/null 2>/dev/null '(0 rows)'
if [ $? -eq 0 ]; then
        echo "[ERROR] Application with id '$app_id' cannot be found into ${KEYSPACE}.app_2. Aborting ..."
        cat ${tmp_dir}/out_2.log
        exit 7
fi

# ${tmp_dir}/out.log is the return from app_for device table
NB_LINES=`wc -l ${tmp_dir}/out.log | awk '{ print $1 }'`
let NB_RECORDS="$NB_LINES-5"
let NB_LAST_LINES="$NB_LINES-3"
app_for_device_records=`tail -n $NB_LAST_LINES ${tmp_dir}/out.log | head -n $NB_RECORDS | sed 's/ //g'`

# Get all Version IDs of this App, 40 60 80, now {tmp_dir}/out.log is the return of app_version table
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select id from ${KEYSPACE}.app_version where app_id='${app_id}';\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
#$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "select id from ${KEYSPACE}.app_version where app_id='${app_id}';"
NB_LINES=`wc -l ${tmp_dir}/out.log | awk '{ print $1 }'`
let NB_RECORDS="$NB_LINES-5"
let NB_LAST_LINES="$NB_LINES-3"

# Basicly, All status of the app should be updated, not matter 40 ,60, 80
records=`tail -n $NB_LAST_LINES ${tmp_dir}/out.log | head -n $NB_RECORDS`


#2019/10/17: this part is for the app_2 which is the new change for multiversion, we need to update app_2 table as well
#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
NB_LINES=`wc -l ${tmp_dir}/out_2.log | awk '{ print $1 }'`
let NB_RECORDS="$NB_LINES-5"
let NB_LAST_LINES="$NB_LINES-3"
records_2=`tail -n $NB_LAST_LINES ${tmp_dir}/out_2.log | head -n $NB_RECORDS|sed 's/ //g'`
#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

# Below are the Update actions for 3 tables

ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select id from ${KEYSPACE}.app_version where app_id='${app_id}';\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
for rec in $app_for_device_records
do
   status=`echo $rec | awk -F\| '{ print $4 }'`

   query="update ${KEYSPACE}.app_for_device set recommended_index=$recommended_index where id='${app_id}' and status=$status;"
   echo "[DEBUG] $query"
   ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"${query}\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
   $CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "$query"
done

echo "===="

for i in $records
do
    query="update ${KEYSPACE}.app_version set recommended_index=$recommended_index where id='$i' and app_id='${app_id}';"
	echo "[DEBUG] $query"
	ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"${query}\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
   	$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "$query"
done
echo "===="
#Update app_2 version
#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
for j in $records_2
do
    version=`echo $j | awk -F\| '{ print $2}' `
    query="update ${KEYSPACE}.app_2 set recommended_index=$recommended_index where id='$i' and version='${version}';"
	echo "[DEBUG] $query"
	ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"${query}\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
   	$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "$query"
done
#VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV

echo "============"