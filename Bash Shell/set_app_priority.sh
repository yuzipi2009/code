#!/usr/bin/env bash
#!/bin/sh

# This script takes 2 parameters:
# app id: the app id to modify
# priority: the priority to set for the provided app id
#
# It will search all app_version of this app and set its priority to the desired value.
#

thedate=`date +'%Y%m%d'`
thetime=`date +'%H%M%S'`

tmp_dir=`mktemp -d`

# Scheduling a delete of the temporary directory in 10 min.
echo "rm -Rf $tmp_dir" | at -m now +10 minute 2>/dev/null

CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"

KEYSPACE=kaicloud

app_id=$1
priority=$2

if [ "x" = "x$priority" ]; then
        echo "[ERROR] Missing mandatory parameters. Aborting ...."
        echo
	echo "Usage: $0   {app id}   {priority}"
	echo "    Example. For whatsapp:"
	echo "    $0 ahLsl7Qj6mqlNCaEdKXv   1"
	exit 1
fi

if [ ! -e "$CQLSH" ]; then
	echo "[ERROR] $CQLSH doesn't exist! Aborting ...".
	exit 2
fi


# Testing connectivity to Cassandra

$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "desc keyspaces"

if [ $? -ne 0 ]; then
    echo >&2 "[ERROR] Failed to connect to Cassandra. Error message follow:"
    cat ${tmp_dir}/error.log
    exit 3
fi

# Making sure the application with the given id exists!
$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "select name from ${KEYSPACE}.app_summary where id='${app_id}';"

if [ $? -ne 0 ]; then
 	echo "[ERROR] Failed to execute query:"
	cat ${tmp_dir}/error.log
	exit 4
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

$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "select id,name,priority,status from ${KEYSPACE}.app_for_device where id='${app_id}';"

tail -1 ${tmp_dir}/out.log | grep >/dev/null 2>/dev/null '(0 rows)'

if [ $? -eq 0 ]; then
        echo "[ERROR] Application with id '$app_id' cannot be found into ${KEYSPACE}.app_for_device. Aborting ..."
        cat ${tmp_dir}/out.log
        exit 6
fi

NB_LINES=`wc -l ${tmp_dir}/out.log | awk '{ print $1 }'`

let NB_RECORDS="$NB_LINES-5"

let NB_LAST_LINES="$NB_LINES-3"

app_for_device_records=`tail -n $NB_LAST_LINES ${tmp_dir}/out.log | head -n $NB_RECORDS | sed 's/ //g'`

$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "select id from ${KEYSPACE}.app_version where app_id='${app_id}';"

NB_LINES=`wc -l ${tmp_dir}/out.log | awk '{ print $1 }'`

let NB_RECORDS="$NB_LINES-5"

let NB_LAST_LINES="$NB_LINES-3"

#echo "NB_RECORDS=$NB_RECORDS   NB_LAST_LINES=$NB_LAST_LINES"

records=`tail -n $NB_LAST_LINES ${tmp_dir}/out.log | head -n $NB_RECORDS`

#echo "Found $NB_RECORDS records ($records) to update!"

for rec in $app_for_device_records
do
   status=`echo $rec | awk -F\| '{ print $4 }'`
   query="update ${KEYSPACE}.app_for_device set priority=$priority where id='${app_id}' and status=$status;"
   echo "[DEBUG] $query"
   $CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "$query"
done

echo "===="

for i in $records
do
        query="update ${KEYSPACE}.app_version set priority=$priority where id='$i' and app_id='${app_id}';"
	echo "[DEBUG] $query"
   	$CQLSH >${tmp_dir}/out.log  2>${tmp_dir}/error.log -e "$query"
done

echo "============"