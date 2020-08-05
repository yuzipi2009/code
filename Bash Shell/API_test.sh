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
   echo "============================================="
   echo "    $1"
   echo "============================================="
   echo
}

check (){

case ${index} in

	account)

        email=`cat return.txt|grep email`
	check=`cat return.txt|grep code|grep cause`
	code_409=`echo ${check}|grep ":409"`
	if [ "${email}x" != "x" ] && [ "${check}x" == "x" ];then
        	echo "${green} OK: Create a new account" && echo "${reset}"
	elif [ "${mac_key}x" == "x" ] && [ "${check}x" != "x" ] && [ "${code_409}x" != "x" ];then
        	echo -e "${green} OK: Already created\n" &&  echo "${check}" && echo "${reset}"
	elif [ "${check}x" != "x" ] && [ "${code_409}x" == "x" ];then
        	echo -e "${red}Failed: Error but not 409\n" && echo "${check}" && echo "${reset}"
	else
                echo -e "${red}Failed: Unknow Error\n" && echo "${check}" && echo "${reset}"
	fi

        ;;

	token)

	mac_key=`cat jwt/${env}_token.json|grep mac_key`
        check=`cat jwt/${env}_token.json|grep code|grep cause`

	if [ "${mac_key}x" != "x" ] && [ "${check}x" == "x" ];then
        	echo "${green}OK: Post token Success" && echo "${reset}"
	elif [ "${mac_key}x" == "x" ] && [ "${check}x" != "x" ];then
        	echo -e "${red}Failed Post token:\n" && echo "${check}" && echo "${reset}"
        else
                echo -e "${red}Failed: Unknow Error\n" && echo "${check}" &&  echo "${reset}"
	fi

        ;;

	app_list)

	icons=`cat return.txt|grep icons`
	check=`cat return.txt|grep code|grep cause`

	if [ "${icons}x" != "x" ]  && [ "${check}x" == "x" ] ;then
                echo "${green}OK: Get app_list Success" && echo "${reset}"
        elif [ "${icons}x" == "x" ] && [ "${check}x" != "x" ];then
                echo -e "${red}Failed Get app_list\n" echo "${check}" && echo "${reset}"
        else
                echo -e "${red}Failed: Unknow error\n" && echo "${check}" && echo "${reset}"
        fi

        ;;

        *)

	echo "index is wrong";exit
esac

}


#check $1

[ "x${env}" == "x" ] && echo "[Error] Must specify a env parameter" && exit

[ "${env}" != "test" ] &&  [ "${env}" != "stage" ] && [ "${env}" != "prod" ] && echo "[Error] env parameter must be test, stage or prod" && exit


echo -e  "==========${today}: Start Check ${env}==========\n"

#Register

log "(1/4) Test register account"

if [  ${env} == "prod" ];then
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_account.json POST https://auth.kaiostech.com/v3.0/accounts>return.txt 2>/dev/null
else
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_account.json POST https://auth.${env}.kaiostech.com/v3.0/accounts>return.txt 2>/dev/null
fi
sleep 1
index=account
check

#Post token

log "(2/4) Post token"
if [  ${env} == "prod" ];then
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.kaiostech.com/v3.0/tokens > jwt/${env}_token.json 2>/dev/null
else
	bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.${env}.kaiostech.com/v3.0/tokens >jwt/${env}_token.json 2>/dev/null
fi
sleep 1
index=token
check

#Fetch app list

log "(3/4) Fetch App List"
if [  ${env} == "prod" ];then
	bin/test_hawk -H "User-Agent: KaiOS/2.5" -c jwt/${env}_token.json GET "https://api.kaiostech.com/v3.0/apps?cu=4044O-2AAQUS0&imei=862413022116274">return.txt 2>/dev/null
else
	bin/test_hawk -H "User-Agent: KaiOS/2.5" -c jwt/${env}_token.json GET "https://api.${env}.kaiostech.com/v3.0/apps?cu=4044O-2AAQUS0&imei=862413022116274">return.txt 2>/dev/null
fi
sleep 1
index=app_list
check

#download icon
#GET png address
# eg., /v3.0/files/app/U/FgN8DwYf7EPshSCjiXoOtdDJc6F5dSjfCmD0fS/ICON_IMAGE.png

log "(4/4) Download png"
png_url=`cat return.txt |grep -Po '/v3.0/files/app\S*?png'|sed -n '1p'`

[ "${png_url}x" == "x" ] && echo "${red}Failed to Get png url, Anorting" && echo "${reset}" && exit

if [  ${env} == "prod" ];then
	bin/test_hawk -c jwt/${env}_token.json https://storage.kaiostech.com${png_url}>png.png 2>/dev/null
else
	bin/test_hawk -c jwt/${env}_token.json https://storage.${env}.kaiostech.com${png_url}>png.png 2>/dev/null

fi

size=`du -sb png.png|awk '{print $1}'`
if [ ${size} -gt 1024 ];then
	echo "${green}OK: Download a icon larger than 1kb" && echo "${reset}"
else
	echo "${red}May failed, less than 1K, check it" && echo "${reset}"
fi
sleep 1

rm -rf ./test-hawk.log.*
echo -e "=============Complete===========\n"