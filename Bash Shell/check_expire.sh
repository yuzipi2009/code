#!/bin/bash

today=`date +%s`

domain_list=(
api.kaiostech.com
services.prod.kaiostech.com
origin.stage.kaiostech.com
dm.fota.kaiostech.com
push.test.kaiostech.com
api.test1.kaiostech.com
open.kaiostech.com
push.kaiostech.com
jenkins.stage.kaiostech.com
)

gen_list=$(
for domain in ${domain_list[*]};
  do
    time=$(echo | openssl s_client -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -noout -dates)
    readable_date=$(echo $time | awk -F "=" '{print $3}' | awk '{print $1" "$2" "$3" "$4}' | awk '{ printf "%02d-%02d-%04d\n", (index("JanFebMarAprMayJunJulAugSepOctNovDec",$1)+2)/3, $2, $4}')
    due_date=`echo "${readable_date}"|awk -F "-" '{print $3$1$2}'`
    due_date_s=`date -d ${due_date} +%s`
    time_interval=$[$[$[${due_date_s}-${today}]/86400]+1]
    #echo "$domain Remain $time_interval days | '$domain'=$time_interval"
    echo "'$domain'=$time_interval "
done
)
IFS=

list=`echo $gen_list| sort -t '=' -k2|tr '\n' ' '`
echo $list
#echo "OK|$list"