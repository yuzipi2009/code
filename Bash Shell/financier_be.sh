#!/bin/sh

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
#Get the prameters {imei} and {tag}:
# example: tag="device-API1" or "notify-API3"

args=("$@")
len_args=${#args[@]}
if [ $len_args -eq 4 ];then
    curef=${args[0]}
    imei=${args[1]}
    tag=${args[2]}
    now=${args[3]}
    echo "imei is $imei, tag is $tag, now is $now"

elif  [ $len_args -eq 3 ];then
      curef=${args[0]}
      tag=${args[1]}
      now=${args[2]}
    echo "tag is $tag, imei is $imei, now is $now"
else
    echo "Wrong prameter arrary, Aborting"
    exit
fi
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

api_output="/tmp/foo.txt"
#hawk="/data/bin/hawk/bin/test_hawk"
hawk_path="/home/yuxiao/Desktop/API_test"
hawk="bin/test_hawk"
jwt="/data/bin/hawk/jwt"
#token_json="${jwt}/token.json"
#login_json="${jwt}/login.json"

token_json="/tmp/token.json"
login_json="/tmp/login.json"

endpoint="https://api.test.kaiostech.com"
today=`date +%Y-%m-%d`

API1="financier_be/v1.0/devices/${imei}"
API2="financier_be/v1.0/devices"
API3="financier_be/v1.0/devices/${imei}/notify_paid"
API4="financier_be/v1.0/devices/notify_paid"
API5="financier_be/v1.0/devices/${imei}/notify_credit_completed"
API6="financier_be/v1.0/devices/notify_credit_completed"

category=`echo ${tag}|awk -F '-' '{print $1}'`
API_temp=`echo ${tag}|awk -F '-' '{print $2}'`
API=`eval echo '$'"${API_temp}"|sed 's#//#/#g'`

function check_curef (){
    #Get the curef from login.json
    curef_now=`jq '.device.reference' ${login_json} |sed 's/"//g'`

    # compare the current curef with the passed curef
    if [ "${curef_now}" == "${curef}" ];then
        # is equal, it is ok, keep the logic without change
        echo "curef is not changed, it is ${curef}"
    else
        # if unequal, post token
        echo "curef is changed, curef_now is  ${curef_now} while passed_curef is ${curef} "
        # replace the new curef with the current curef
        sed -i "s/${curef_now}/${curef}/g" ${login_json}|| { echo "sed failed,Aborting";exit;}
        # post curef
        ${hawk}  -H 'Content-Type:application/json' -d @${login_json} POST ${endpoint}/oauth2/v1.0/tokens >${token_json}
        if [ $? -eq 0 ];then
            echo "post success"
        else
            echo "post failed"
        fi
    fi
}

function check_token_expire (){
    check1=`grep -Po "401" ${api_output}`
    check2=`grep -Po  "201 Created|202" ${api_output}`
    #echo "check1 is $check1"
    #echo "check2 is $check2"

    cd ${hawk_path}
    if [ "x" != "${check1}x" ];then
        # repost token
        ${hawk}  -H 'Content-Type:application/json' -d @${login_json} POST ${endpoint}/oauth2/v1.0/tokens >${token_json}
        #echo "renewed the token"
        return 401
    elif [ "x" != "${check2}x" ];then
        #echo "the api output is normal"
        return 201
    else
       echo "soemthing wrong in the api output"
       exit
fi

}

cd ${hawk_path}

if [ "x${imei}" == "x" ] || [ "x${tag}" == "x" ];then
	echo "[Error] Must specify the imei and tag parameter"
	exit
fi

echo  "==========${today} =========="


case ${category} in

    devices)
    check_curef
    while true;do
        ${hawk} -H 'Content-Type:application/json' -c ${token_json} GET ${endpoint}/${API} > ${api_output} 2>&1
        check_token_expire
        echo "the function return is: $?"
        if [ $? -eq 201 ];then
            break
        fi
    done
    ;;

    notify)
    check_curef
    while true;do
        ${hawk} -H 'Content-Type:application/json' -d @/tmp/notify_${now}.json -c ${token_json} POST ${endpoint}/${API} > ${api_output} 2>&1
        echo "start"
	check_token_expire
        if [ $? -eq 201 ];then
            echo "OK, api return  is normal, break!"
            cat ${api_output}
            break
        fi
    done
    ;;

    complete)
    check_curef
    #check=`grep "next_pay_dl ${jwt}/next_pay.json"`
    #if [ $? -eq 0 ] && [ "x" != "x${check}" ];then
    while true;do
        ${hawk} -H 'Content-Type:application/json' -d @/tmp/notify_${now}.json -c ${token_json} POST ${endpoint}/${API} > ${api_output} 2>&1
        check_token_expire
        if [ $? -eq 201 ];then
            echo "OK, api return  is normal, break!"
            cat ${api_output}
            break
        fi
    done
    ;;

    *)

    echo "invalid category, it should be devices/notify/complete"
    exit

    ;;

esac