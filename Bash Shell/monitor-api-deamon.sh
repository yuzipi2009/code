#!/usr/bin/env bash

# define variable
path="s3://packages.production/base_19/"
now=`date "+%Y-%m-%d_%H:%M"`

# obtain the last_check time
last_check=`cat now/now_19.txt`
refer=${1-"base19_${last_check}"}

# Fuction: Generate Ajax for table: show_app

ajax () {
   echo "    {"
   echo "      \"Check_Time\": \"${now}\","
   echo "      \"packages.toml\": \"${status}\","
   echo "      \"Action\": \"${action}\""
   echo "    },"
}

# Get the list of base19 of "now"
aws s3 ls ${path}|awk '{print $4}'> list/base19_${now}
check=`grep "packages.toml" list/base19_${now}`
if [ "x${check}" == "xpackages.toml" ];then
    status="Existing"
else
    status="Miss"
fi
# compare the file list with the refer
cat list/${refer} list/base19_${now} |sort|uniq -u > diff/diff.base19_${now}.txt

# override the last_check time
echo ${now} > now/now_19.txt

#judge the file is deleted or added or no change
count=0
no_diff=`cat diff/diff.base19_${now}.txt`
if [ "x" == "${no_diff}x" ];then
    action="no file change"
else
    for file in `cat diff/diff.base19_${now}.txt`;do
        delete=`grep ${file} list/${refer}`
        add=`grep ${file} list/base19_${now}`
        if [ "x${delete}" == "x" ] && [ "x${add}" != "x" ];then
            change="Add ${file}"
        elif [ "x${delete}" != "x" ] && [ "x${add}" == "x" ];then
            change="Delete ${file}"
        else
            change="Exception"
        fi
        if [ ${count} -eq 1 ];then
            echo -n "${change}" > action/action_${now}
        else
            echo -n "<br/>${change}" >> action/action_${now}
        fi
    done
    action=`cat action/action_${now}`
fi

# Generate ajax json
# back_up old api-data.json and create the head of new file
mv api-data.json json_dir/api-data.json_${now}
echo "{" > api-data.json
echo "  \"data\": [" >> api-data.json
ajax >> api-data.json


# cp api-data.json to datatables dir
ajax_dir="/data/tools/repository/nginx/html/static/kaios_app/datatables"


