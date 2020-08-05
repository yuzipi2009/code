#!/bin/bash


current_dir=`dirname $0`
res_dir=`cd ${current_dir} && pwd`
abs_dir=${res_dir}
test_cass="10.81.74.132"
env="kaicloud_test"
cass_bin="/data/tools/repository/apache-cassandra/bin"
today=`date "+%Y-%m-%d_%H:%M"`

:<<!
#Fetch tables to cassandra nodes
ssh  ${test_cass} "sudo su - cassadmin -c \"${cass_bin}/cqlsh -e \\\"copy ${env}.app_summary(id,display_name) to '/tmp/summary2.csv' with null='<null>' \\\" && chmod 755 /tmp/summary2.csv \""
ssh  ${test_cass} "sudo su - cassadmin -c \"${cass_bin}/cqlsh -e \\\"copy ${env}.app_version(app_id,icons,zip_url) to '/tmp/version2.csv' with null='<null>' \\\" && chmod 755 /tmp/version2.csv \""

# Copy to GK
[[ $? -eq 0 ]] && scp ${test_cass}:/tmp/version2.csv /tmp && scp ${test_cass}:/tmp/summary2.csv /tmp || { echo "Copy app_version or app_summary from cassandra failed, Aborting";exit;}
!
#remove space
#sed -i 's/ //g' /tmp/version2.csv  && sed -i 's/ //g' /tmp/summary2.csv

#Don't remove the spcases, because it is easy to filter with space, just need to change IFS
OLD_IFS=$IFS
IFS=$'\n'

#reset the icon.txt
cat /dev/null > icon.txt
cat /dev/null  > zip.txt

#Get app_id ,display_name, and zip_url
for line in `cat /tmp/summary2.csv`;do
    filter=`echo ${line}|grep -i 'DoNotTouch'`
    if [ "${filter}x" == "x" ];then
        #get the app_id which doesn't contain "DoNotTouch"
        app_id=`echo ${line}|awk -F, '{print $1}'`

        if [[ ! ${app_id}] =~ ^[0-9a-zA-Z] ]];then
            line2=`grep '\'"${app_id}" /tmp/version2.csv`
        else
            line2=`grep ${app_id} /tmp/version2.csv`
        fi
        display_name=`echo ${line}|awk -F, '{print $2}'|sed 's/ //g'`
        #echo "Found matched lines, $display_name"

        #there may be several lines with the same app_id
        for line3 in `echo "${line2}"`;do
            echo "is $line3"
            echo $line3|grep -Po "/\S/\S+/ICON_IMAGE.\S+\'"|sed "s/'//g" >>icon.txt
            echo $line3|grep -Po ",/\S/\S+/APP_ZIP_FILE.zip"|sed 's/,//g'>>zip.txt
        done
    else
        #echo "Found the line with "DoNotTouch", skip..."
        :
    fi
done
IFS=$OLD_IFS
#<<<<<<Now we get the icon and zip directory>>>>>>>>>>


