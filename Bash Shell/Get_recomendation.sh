#!/bin/bash

# This script takes 3 parameters:
# env: test or stage
# app id: the app id to modify
# recommeded index: the recommended index to set for the provided app id
#
# It will search all app_version/app_for_device/app2 tables of this app and set its recommended_index to the desired value.
#

readonly red=$(tput bold; tput setaf 1)
readonly green=$(tput bold; tput setaf 2)
readonly reset=$(tput sgr0)

thedate=`date +'%Y%m%d'`
thetime=`date +'%H%M%S'`
tmp_dir=`mktemp -d`

# Scheduling a delete of the temporary directory in 10 min.
echo "rm -Rf $tmp_dir" | at -m now +10 minute 2>/dev/null

CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"
env=$1
app_id=$2
recommended_index=$3

#echo -n "[1/4] Check Arguments ...."
if [ "x" = "x$env" ]; then
        echo "Failed"
        echo "[ERROR] Missing mandatory parameters. Aborting ...."
        echo
	echo "Usage: $0  ${env}   ${app_id}(Optional)"
	exit 1
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
#echo -n "[2/4] Check Cqlsh...."
ssh ${user}@${gk} "ssh ${cass} \"test -e \\\"$CQLSH\\\"\""|| { echo "Failed" && echo "[ERROR] $CQLSH doesn't exist! Aborting ..." && exit 2;}


# Testing connectivity to Cassandra
#echo -n "[3/4] Check Cassandra Connectivity...."
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"desc keyspaces\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log
if [ $? -ne 0 ]; then
    echo "Failed"
    echo >&2 "[ERROR] Failed to connect to Cassandra. Error message follow:"
    cat ${tmp_dir}/error.log
    exit 3
fi



##function 1

function get_single () {

# Making sure the application with the given id exists in app_summary table
#echo -n "[4/4] Check APP...."
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select name from ${KEYSPACE}.app_summary where id='${app_id}';\\\\\\\" \\\"\"" >${tmp_dir}/out.log  2>${tmp_dir}/error.log

if [ $? -ne 0 ]; then
    echo "Failed"
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

echo "Found application '$app_name' with id '$app_id'"

#Get display, version index from app_2 table
echo "${green}APP_2 table:" && echo ${reset}
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select display,version, recommended_index from ${KEYSPACE}.app_2 where id='${app_id}';\\\\\\\" \\\"\""|sed 's/ //g;3d;$d' |tee ${tmp_dir}/app_2.log  2>${tmp_dir}/app_2.out


# Get from app_version table
echo "APP_Version table:"
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select version,supported_platforms,version_status,recommended_index from ${KEYSPACE}.app_version where app_id='${app_id}';\\\\\\\" \\\"\"" |sed 's/ //g;3d;$d'|tee ${tmp_dir}/version.log  2>${tmp_dir}/version.out

}

##function 2

function get_all() {
#Get display, version index from app_2 table and the index is not null or 0
echo "${green}APP_2 table (only show the app set index > 0):" && echo ${reset}
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select display,version, recommended_index from ${KEYSPACE}.app_2;\\\\\\\" \\\"\"" |sed 's/ //g;3d;$d'|awk -F '|' '{if ($3 != 0 && $3 != "null") print $0}'|tee ${tmp_dir}/app_2.log  2>${tmp_dir}/app_2.out

wc=`wc -l ${tmp_dir}/app_2.log|awk '{print $1}'`
[ $wc -eq 5 ] && echo "No App is set recomendation index"

# Get from app_version table
echo "APP_Version table (only show the app set index > 0):"
ssh ${user}@${gk} "ssh ${cass} \"sudo su - cassadmin -c \\\"$CQLSH  -e \\\\\\\"select version,supported_platforms,version_status,recommended_index from ${KEYSPACE}.app_version;\\\\\\\" \\\"\""|sed 's/ //g;3d;$d' |awk -F '|' '{if ($4 != 0 && $4 != "null") print $0}' |tee ${tmp_dir}/app_2.log  2>${tmp_dir}/app_2.out

wc=`wc -l ${tmp_dir}/app_2.log|awk '{print $1}'`
[ $wc -eq 3 ] && echo "No App is set recomendation index"

}

# main

if [ "x" == "${app_id}x" ];then
    get_all
else
    get_single
fi