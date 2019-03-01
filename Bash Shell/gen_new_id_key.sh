#!/usr/bin/env bash

# This script is used to create a new ID/Key embedded into the phone
# for both Kai Store and Push manager passwordless access. It takes
# as parameter a project name and will automatically create new ID/Keys
# for this project into the databases of Stage, Preprod and Production.
#
# Usage:
# ./bin/gen.sh  {project name}
#
# Examples:
# ./bin/gen.sh  Gold
#
# When project name contain space, use simple or double quotes around name.
# ./bin/gen.sh  'My New Project'
#

# Determine the script name.
EXEC_NAME=`basename $0`

# Relative directory
REL_TOOLS_DIR=`dirname $0`

# Calculating the Absolute Base directory of the tools.
ABS_BASE_DIR=`cd ${REL_TOOLS_DIR}/..; pwd`

# Deriving the absolute bin directory
ABS_BIN_DIR="${ABS_BASE_DIR}/bin"


UUID_GEN=${ABS_BIN_DIR}/test_uuid


GK_USR=iot-user
CASSADM_USR=cassadmin


# Checking dependency availability
if [ ! -f ${UUID_GEN} ]; then
    echo >&2 "[ERROR] Failed to find ${UUID_GEN}. Aborting ..."
    exit 1
fi

if [ ! -e ${UUID_GEN} ]; then
    echo >&2 "[ERROR] Failed to execute ${UUID_GEN}. Aborting ..."
    exit 2
fi

PROJECT_NAME=$1

if [ "x" = "x${PROJECT_NAME}" ]; then
    echo >&2 "[ERROR] Missing project name as parameter. Aborting ..."
    exit 3
fi

NEW_ID=`${UUID_GEN} | head -1`
NEW_KEY=`${UUID_GEN} | head -1`

NEW_ID2=`${UUID_GEN} | head -1`
NEW_KEY2=`${UUID_GEN} | head -1`


#echo "NEW_ID=$NEW_ID NEW_KEY=$NEW_KEY"

thedate=`date +'%Y%m%d'`
thetime=`date +'%H%M%S'`

tmp_dir=`mktemp -d`


# Scheduling a delete of the temporary directory in 10 min.
echo "rm -Rf $tmp_dir" | at -m now +10 minute 2>/dev/null


env_list="34.193.231.19:172.31.13.22:172.31.1.243:kaicloud_stage:stage 34.193.180.253:192.168.78.165:192.168.50.209:kaicloud_stage:preprod 34.228.28.86:172.31.35.124:172.31.3.192:kaicloud:production"


# First loop is just to verify accessibility. If any failure happens, then we will just stop here.
for record in ${env_list}
do
    GK=`echo $record | awk -F: '{ print $1 }'`
    CMGR=`echo $record | awk -F: '{ print $2 }'`
    CASSDB=`echo $record | awk -F: '{ print $3 }'`
    KS=`echo $record | awk -F: '{ print $4 }'`
    environment=`echo $record | awk -F: '{ print $5 }'`

    #echo "GK=$GK CMGR=$CMGR  CASSDB=$CASSDB  KS=$KS"
    echo -n "Verifying accessibility to $environment ... "

    control_msg="Hello $thedate $thetime $tmp_dir"

    msg_result=$(ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} echo "${control_msg}")

    if [ "$msg_result" != "$control_msg" ]; then
        echo "FAILED"
 	    echo >&2 "[ERROR] Your current account is not authorized to SSH to '${GK}' as '${GK_USR}'. Error message follows:"
        echo >&2 "Obtained control msg: '$msg_result', Expected control msg:'$control_msg'"
	    cat $tmp_dir/error.log
	    exit 4
    fi

    msg_result=$(ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} "ssh ${GK_USR}@${CMGR} echo \"${control_msg}\"")

    if [ "$msg_result" != "$control_msg" ]; then
        echo "FAILED"
 	    echo >&2 "[ERROR] Your current account is not authorized to SSH to ${CMGR} via'${GK}'. Error message follows:"
        echo >&2 "Obtained control msg: '$msg_result', Expected control msg:'$control_msg'"
	    cat $tmp_dir/error.log
	    exit 5
    fi

    msg_result=$(ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} "ssh ${GK_USR}@${CMGR} \"sudo su - cassadmin -c \\\"ssh ${CASSDB} \\\\\\\"echo \\\\\\\\\\\\\\\"${control_msg}\\\\\\\\\\\\\\\"\\\\\\\"\\\"\"")

    if [ "$msg_result" != "$control_msg" ]; then
        echo "FAILED"
 	    echo >&2 "[ERROR] Your current account is not authorized to SSH to ${CMGR} via'${GK}'. Error message follows:"
        echo >&2 "Obtained control msg: '$msg_result', Expected control msg:'$control_msg'"
	    cat $tmp_dir/error.log
	    exit 6
    fi

    echo "OK"

done

# Second loop is where we actually perform the new key creation.
for record in ${env_list}
do
    GK=`echo $record | awk -F: '{ print $1 }'`
    CMGR=`echo $record | awk -F: '{ print $2 }'`
    CASSDB=`echo $record | awk -F: '{ print $3 }'`
    KS=`echo $record | awk -F: '{ print $4 }'`
    environment=`echo $record | awk -F: '{ print $5 }'`

    #echo "GK=$GK CMGR=$CMGR  CASSDB=$CASSDB  KS=$KS"
    echo -n "Registering keys for $environment in service ... "

    # Dry Run - below line do not modify the database.
    #result=$(ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} "ssh ${GK_USR}@${CMGR} \"sudo su - cassadmin -c \\\"ssh ${CASSDB} \\\\\\\"/data/tools/repository/apache-cassandra/bin/cqlsh >/dev/null -e \\\\\\\\\\\\\\\"COPY ${KS}.service TO '/tmp/service.csv'\\\\\\\\\\\\\\\" && grep >/tmp/new.csv Silver /tmp/service.csv &&  sed -i 's/D_EE7Bpm2lRV_8Q-rfjZ/${NEW_ID}/g' /tmp/new.csv && sed -i 's/SVjyDn_BSynaR2ZDac29/${NEW_ID2}/g' /tmp/new.csv && sed -i 's/FbIYmf03GbPt6Pz6uveS/${NEW_KEY}/g' /tmp/new.csv && sed -i 's/NqTcb2iOwEaySpbCu6_O/${NEW_KEY2}/g' /tmp/new.csv && sed -i 's/Silver/${PROJECT_NAME}/g' /tmp/new.csv &&  cat /tmp/new.csv && echo \\\\\\\"\\\"\"")

    # Actual Action
    ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} "ssh ${GK_USR}@${CMGR} \"sudo su - cassadmin -c \\\"ssh ${CASSDB} \\\\\\\"/data/tools/repository/apache-cassandra/bin/cqlsh >/dev/null -e \\\\\\\\\\\\\\\"COPY ${KS}.service TO '/tmp/service.csv'\\\\\\\\\\\\\\\" && grep >/tmp/new.csv Silver /tmp/service.csv &&  sed -i 's/D_EE7Bpm2lRV_8Q-rfjZ/${NEW_ID}/g' /tmp/new.csv && sed -i 's/SVjyDn_BSynaR2ZDac29/${NEW_ID2}/g' /tmp/new.csv && sed -i 's/FbIYmf03GbPt6Pz6uveS/${NEW_KEY}/g' /tmp/new.csv && sed -i 's/NqTcb2iOwEaySpbCu6_O/${NEW_KEY2}/g' /tmp/new.csv && sed -i 's/Silver/${PROJECT_NAME}/g' /tmp/new.csv &&  /data/tools/repository/apache-cassandra/bin/cqlsh >/dev/null -e \\\\\\\\\\\\\\\"COPY ${KS}.service FROM '/tmp/new.csv'\\\\\\\\\\\\\\\"\\\\\\\"\\\"\""

    if [ $? -ne 0 ]; then
        echo FAILED
    else
        echo OK
    fi

    echo -n "Registering keys for $environment in application ... "

    # Dry Run - below line do not modify the database.
    #result=$(ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} "ssh ${GK_USR}@${CMGR} \"sudo su - cassadmin -c \\\"ssh ${CASSDB} \\\\\\\"/data/tools/repository/apache-cassandra/bin/cqlsh >/dev/null -e \\\\\\\\\\\\\\\"COPY ${KS}.application TO '/tmp/application.csv'\\\\\\\\\\\\\\\" && grep >/tmp/new.csv Silver /tmp/application.csv &&  sed -i 's/D_EE7Bpm2lRV_8Q-rfjZ/${NEW_ID}/g' /tmp/new.csv && sed -i 's/SVjyDn_BSynaR2ZDac29/${NEW_ID2}/g' /tmp/new.csv && sed -i 's/FbIYmf03GbPt6Pz6uveS/${NEW_KEY}/g' /tmp/new.csv && sed -i 's/NqTcb2iOwEaySpbCu6_O/${NEW_KEY2}/g' /tmp/new.csv && sed -i 's/Silver/${PROJECT_NAME}/g' /tmp/new.csv &&  cat /tmp/new.csv && echo \\\\\\\"\\\"\"")

    ssh 2>$tmp_dir/error.log ${GK_USR}@${GK} "ssh ${GK_USR}@${CMGR} \"sudo su - cassadmin -c \\\"ssh ${CASSDB} \\\\\\\"/data/tools/repository/apache-cassandra/bin/cqlsh >/dev/null -e \\\\\\\\\\\\\\\"COPY ${KS}.application TO '/tmp/application.csv'\\\\\\\\\\\\\\\" && grep >/tmp/new.csv Silver /tmp/application.csv &&  sed -i 's/D_EE7Bpm2lRV_8Q-rfjZ/${NEW_ID}/g' /tmp/new.csv && sed -i 's/SVjyDn_BSynaR2ZDac29/${NEW_ID2}/g' /tmp/new.csv && sed -i 's/FbIYmf03GbPt6Pz6uveS/${NEW_KEY}/g' /tmp/new.csv && sed -i 's/NqTcb2iOwEaySpbCu6_O/${NEW_KEY2}/g' /tmp/new.csv && sed -i 's/Silver/${PROJECT_NAME}/g' /tmp/new.csv &&  /data/tools/repository/apache-cassandra/bin/cqlsh >/dev/null -e \\\\\\\\\\\\\\\"COPY ${KS}.application FROM '/tmp/new.csv'\\\\\\\\\\\\\\\"\\\\\\\"\\\"\""

    if [ $? -ne 0 ]; then
        echo FAILED
    else
        echo OK
    fi

done

echo
echo "------------ SEND TO CE Team 2 lines below -----------------------------------"
echo "${PROJECT_NAME}    App Store, id: ${NEW_ID},  key: ${NEW_KEY}"
echo "${PROJECT_NAME} Push Manager, id: ${NEW_ID2},  key: ${NEW_KEY2}"
echo "------------------------------------------------------------------------------"gg