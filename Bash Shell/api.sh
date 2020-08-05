#!/usr/bin/env bash
#!/bin/sh

#
env=$1
#bin="/home/yuxiao/Desktop/change_cu/bin"
#jwt="/home/yuxiao/Desktop/change_cu/jwt"
today=`date +%Y-%m-%d`

readonly red=$(tput bold; tput setaf 1)
readonly green=$(tput bold; tput setaf 2)
readonly reset=$(tput sgr0)

log () {
   echo
   echo "============================================="
   echo "    $1"
   echo "============================================="
   echo
}

check (){

check=`cat return.txt|grep code|grep cause`
code_409=`echo ${check}|grep ":409"`
if [ "${check}x" == "x" ];then
        echo "${green}OK" && echo "${reset}"
elif [ "${code_409}x" != "x" ];then
        echo "${green}conflict OK" && echo "${reset}"
else
        echo "${red}Failed" && echo "${reset}"
fi

}

#check $1

[ "x${env}" == "x" ] && echo "[Error] Must specify a env parameter" && exit

echo "env is ${env}"
[ "${env}" != "test" ] &&  [ "${env}" != "stage" ] && [ "${env}" != "prod" ] && echo "[Error] env parameter must be test, stage or prod" && exit


echo -e "=============${today}===========\n"

#Register

log "(1/4) Test register account"

if [  ${env} == "prod" ];then
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_account.json POST https://auth.kaiostech.com/v3.0/accounts>return.txt 2>/dev/null
else
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_account.json POST https://auth.${env}.kaiostech.com/v3.0/accounts>return.txt 2>/dev/null
fi
sleep 1
check

#Post token

log "(2/4) Post token"
if [  ${env} == "prod" ];then
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.kaiostech.com/v3.0/tokens >return.txt 2>/dev/null
else
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.${env}.kaiostech.com/v3.0/tokens >return.txt 2>/dev/null
fi
sleep 1
check

#Fetch app list

log "(3/4) Fetch App List"
if [  ${env} == "prod" ];then
	bin/test_hawk -H "User-Agent: KaiOS/2.5" -c jwt/${env}_token.json GET "https://api.kaiostech.com/v3.0/apps?cu=4044O-2AAQUS0&imei=862413022116274">return.txt 2>/dev/null
else
	bin/test_hawk -H "User-Agent: KaiOS/2.5" -c jwt/${env}_token.json GET "https://api.${env}.kaiostech.com/v3.0/apps?cu=4044O-2AAQUS0&imei=862413022116274">return.txt 2>/dev/null
fi
sleep 1
check

#download icon
#GET png address
# eg., /v3.0/files/app/U/FgN8DwYf7EPshSCjiXoOtdDJc6F5dSjfCmD0fS/ICON_IMAGE.png

log "(4/4) Download png"
png_url=`cat return.txt |grep -Po '/v3.0/files/app\S*?png'|sed -n '1p'`

[ "${png_url}x" == "x" ] && echo "Failed to Get png url, Anorting" && exit

if [  ${env} == "prod" ];then
	bin/test_hawk -c jwt/${env}_token.json https://storage.kaiostech.com${png_url}>png.png 2>/dev/null
else
	bin/test_hawk -c jwt/${env}_token.json https://storage.${env}.kaiostech.com${png_url}>png.png 2>/dev/null
fi
sleep 1
check

echo -e "=============Complete===========\n"
