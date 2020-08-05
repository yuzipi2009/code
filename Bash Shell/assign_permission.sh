#!/bin/bash

rel_dir=`dirname $0`
abs_dir=`cd $rel_dir;pwd`
current_dir=${abs_dir}
CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"
hawk="/data/tools/repository/apache-cassandra/test_hwak"
login_name=$1
role_id=$2
key_space="kaicloud_test"

# check test_hawk
if [ ! -f "${current_dir}/test_hawk" ];then
    echo "[Error] you must have test_hawk script in te directory"
    exit
fi


#HELP option <chang to your token here>

if [ "$1" == "-h" ];then
    #Post token
    ${current_dir}/test_hawk -H 'Content-Type:application/json' -d @${current_dir}/../jwt/test_login.json POST https://api.test.kaiostech.com/v3.0/tokens > ${current_dir}/../jwt/test_token.json
    [ $? -ne 0 ] && echo "Post token failed"
    # GEt roles
    ${hawk}/bin/test_hawk -c ${hawk}/jwt/test_token.json GET https://api.test.kaiostech.com/v3.0/system/roles|jq '.[]|{id,name,description}'
    echo "[INFO] You can select the role_id from top "
    exit

# check $1 and $2
elif [ "${login_name}x" == "x" ] || [ "${role_id}x" == "x" ];then
    echo "[Error] Must give login_account and the role_id as arguments, Aborting"
    exit
fi

# check from_seed
if [ ! -f "${hawk}/bin/from_seed" ];then
    echo "[Error] you must have from_seed script in te directory"
    exit
fi

#GET lid
lid=`${current_dir}/from_seed ${login_name}`
if [ "${lid}x" == "x" ];then
    echo "[Error] lid is empty, Aborting"
    exit
else
    echo "================================================="
    echo "Get login_id ${lid}"
fi
#GET aid with lid
row=`${CQLSH} -e "select * from  ${key_space}.login2account where lid='${lid}'"|grep 'rows'|awk '{print $1}'|sed 's/(//g'`

aid=`${CQLSH} -e "select * from  ${key_space}.login2account where lid='${lid}'"|grep '|'|sed -n '$p'|awk -F '|' '{print $NF}'|sed 's/ //g'`

if [ ${row} -eq 0 ];then
    echo "[Error] aid is empty, Aborting"
    exit
else
    echo "================================================="
    echo "Get account_id ${aid}"
fi
#Assign the target role_id to the account

${CQLSH} -e "INSERT INTO ${key_space}.account2role (account_id,role_id,deleted) VALUES ('${aid}', '${role_id}',False)"
if [ $? -eq 0 ];then
    echo "================================================="
    echo "Add Role_ID \"${role_id}\" to ${login_name}"
fi

#POST_check
echo "========================POST_CHECK=================="
${CQLSH} -e "SELECT * FROM ${key_space}.account2role where account_id='${aid}'"