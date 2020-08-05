#!/bin/bash

current_dir=`dirname $0`
res_dir=`cd ${current_dir} && pwd`
abs_dir=${res_dir}
cu_repository=$(cd ${abs_dir}/`date +%Y%m%d`;pwd)

# fetch the new access token firstly in case of expire
./bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.kaiostech.com/v3.0/tokens >jwt/prod_token.jsoni
[ $? -eq 0 ] && echo "new access token is fetched" || { echo "fetch access token error";exit5;}

#loop all the new_cu.json file
for new_cu_json in `ls ${cu_repository}`;do
    ./bin/test_hawk -H "Content-Type: application/json" -d @${cu_repository}/${new_cu_json} -c jwt/prod_token.json POST https://api.kaiostech.com/v3.0/curef >> var/post_result.txt
    return=`echo $?`

    echo "new cu json is ${new_cu_json}"

    echo -n "Post cu_${new_cu} ..."
    if [[ "${return}x" != "x" ]];then
        echo "Failed!!!"

    else
        echo "OK"
    fi
done



rm -rf cass_curef.csv
mv  fota_cu.xls fota_cu.xls_used
rm -rf test-hawk.log*
mv var/post_result.txt var/post_result.txt.`date +%Y%m%d`
mv ${cu_repository} ${cu_repository}_used