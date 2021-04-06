#!/bin/bash

current_dir=`dirname $0`
res_dir=`cd ${current_dir} && pwd`
abs_dir=${res_dir}
user="iot-user"
prod_gk="34.228.28.86"
prod_cass="172.31.4.248"
env="kaicloud"
cass_bin="/data/tools/repository/apache-cassandra/bin"
today=`date "+%Y-%m-%d_%H:%M"`
today2=`date "+%Y-%m-%d"`

# define {code:category} map
declare -A code2category
declare -A id2module
declare -A id2cu

code2category[10]="Games"
code2category[20]="Entertainment"
code2category[30]="Social"
code2category[40]="Shopping"
code2category[50]="News"
code2category[60]="Utilities"
code2category[70]="Lifestyle"
code2category[80]="Health"
code2category[90]="Sports"
code2category[100]="Books & Reference"

# Fuction: Generate Ajax for table: show_app

ajax_app () {
   echo "    {"
   echo "      \"Developer\": \"${developer}\","
   echo "      \"Icon\": \"${icon}\","
   echo "      \"App_Name\": \"${app_name}\","
   echo "      \"App_ID\": \"${app_id}\","
   echo "      \"Category\": \"${category}\","
   echo "      \"Type\": \"${type}\","
   echo "      \"Current_Version\": \"${version}\","
   echo "      \"Publish_Date\": \"${publish_date}\"",
   echo "      \"Version_history\": \"${version_history}\"",
   echo "      \"White_module\": \"${white_module}\"",
   echo "      \"Support_OS\": \"${os}\"",
   echo "      \"Category_Code\": \"${code}\""
   echo "    },"
}

# Fuction: Generate Ajax for table: show_app

ajax_curef () {
   echo "    {"
   echo "      \"Curef\": \"${cu}\","
   echo "      \"Brand_Model\": \"${module}\""
   echo "    },"
}

#:<<!
# Fech summary and version table and copy to cassandra node
mv app_version.csv csv_history/app_version.csv_${today}
mv app_summary.csv csv_history/app_summary.csv_${today}
mv curef.csv csv_history/curef.csv_${today}

ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/app_version.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.app_version to '/tmp/app_version.csv' with header=true and null='<null>' \\\\\\\" && chmod 755 /tmp/app_version.csv \\\"\""
ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/curef.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.curef to '/tmp/curef.csv' with header=true and null='<null>' \\\\\\\" && chmod 755 /tmp/curef.csv \\\"\""
ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/app_summary.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.app_summary to '/tmp/app_summary.csv' with header=true and null='<null>' \\\\\\\" && chmod 755 /tmp/app_summary.csv \\\"\""

# Copy to GK5
[[ $? -eq 0 ]] && ssh ${user}@${prod_gk} "rm -rf /tmp/app_version.csv /tmp/app_summary.csv /tmp/curef.csv ; scp ${prod_cass}:\"/tmp/app_version.csv /tmp/app_summary.csv /tmp/curef.csv\" /tmp" || { echo "Copy app_version or app_summary or curef from cassandra failed, Aborting";exit;}

# Copy to local
[[ $? -eq 0 ]] && rm -rf app_version.csv  app_summary.csv  curef.csv; scp ${user}@${prod_gk}:"/tmp/app_version.csv /tmp/app_summary.csv /tmp/curef.csv" ./ && echo "Fetch 3 tables to local.. OK"|| { echo "Copy app_version or app_summary or curef from K5-GK failed, Aborting";exit;}

# cut head and remove space
sed -i '1d' app_version.csv && sed -i 's/\s\+//g' app_version.csv

sed -i 's/\s\+//g' curef.csv && sed -i '1d' curef.csv

#sed -i '1d' ${abs_dir}/app_summary.csv && sed -i 's/\s\+//g' ${abs_dir}/app_summary.csv
#!
# clean category.txt
cat /dev/null >  category.txt

#=============================================================================
# New extension: whitelist, below loop is to get 2 maps and a file for curef, and a curef ajax
rm -rf whitelist/*.txt
rm -rf ./manifest/app_id.txt

echo "{" > curef.json
echo "  \"data\": [" >> curef.json

for line_3 in `cat curef.csv`;do
curef_id=`echo ${line_3}|awk -F ',' '{print $1}'`
cu=`echo ${line_3}|awk -F ',' '{print $2}'`
module=`echo ${line_3}|awk -F ',' '{print $3}'`
id2cu[$curef_id]=$cu
id2module[$curef_id]=$module
echo ${curef_id} >> whitelist/full_cu_id_list.txt
ajax_curef >> curef.json
done

# delete the last "," for curef.ajax
sed -i '$s/,//g' curef.json
echo "  ]" >> curef.json
echo "}" >> curef.json
echo "====CUREF_ajax generated completed===="
#==================================================================================

# Basic method:
#1) Get App_id , developer, status_code, update_date, version by loop app_version.csv
#2) Get App_name and category from app_summary.csv by filter the app_id
#3) only status=80 is valid

# back_up old data.json and create the head of new file
mv data.json json_dir/data.json_${today}

echo "{" >> data.json
echo "  \"data\": [" >> data.json

# num is used to count the number of apps
num=0
# back_version is used to backup app_version directory
back_version=0

#Get the former data of date and number
old_date=`cat table_head/today.txt`
old_num=`cat table_head/num.txt`
echo "====Today is ${today}===="
for line in `cat app_version.csv`;do

    #Get Status
    status_code=`echo ${line}|awk -F ',' '{print $(NF-1)}'`

    if [ ${status_code} -eq 80 ];then
        #Get Category#Get App ID
        app_id=`echo ${line}|awk -F ',' '{print $1}'`
        #Get Publish_Date
        update_date=`echo ${line}|awk -F ',' '{print $(NF-4)}'|awk -F ':' '{print $1}'|grep -Po '\S+-\S+-\d\d'`
        #Get Version
        version=`echo ${line}|awk -F ',' '{print $(NF-3)}'`
        #Get developer
        developer=`echo ${line}|grep -Po 'name:\S*?,'|sed -n '1p'|sed "s/name://g;s/,//g;"s/\'//g""`
        #VVVVVVVVVVVVVVVVVVVVVV Get iconVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
        icon_temp=`echo ${line}|grep -Po "/\S+/\S+/*.png"|awk -F\' '{print $NF}'`
        if [ "${icon_temp}x" == "x" ];then
		icon="null"
                echo "empty icon: $app_id -> ${icon_temp}"
        elif [[  ${icon_temp}  =~  ^[/] ]];then 
        	icon="https://api.kaiostech.com/v3.0/files/app${icon_temp}"
        else
		icon=${icon_temp}
        fi
        #VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
        #Get support OS
        os=`echo ${line}|awk -F '[{}]' '{print $(NF-1)}'`

        # Filter app_id in app_summary.csv to get category and app_name
        if [[ ! ${app_id}] =~ ^[0-9a-zA-Z] ]];then
            line_2=`grep '\'"${app_id}" app_summary.csv`
        else
            line_2=`grep ${app_id} app_summary.csv`
        fi

        if [ "${line_2}x" == "x" ];then
            echo "can't find this app_id in app_summary.csv, ${app_id}"
        else
            app_name=`echo ${line_2}|sed 's/{.*}/null/g'|awk -F ',' '{print $(NF-15)}'`
            #app_name=`echo ${line_2}|awk -F '[{}<>]' '{print $3}'|sed 's/[^a-zA-Z]//g'`
            code=`echo ${line_2}|awk -F ',' '{print $2}'`
            category=`echo ${code2category[$code]}`
            type=`echo ${line_2}|awk -F ',' '{print $(NF-2)}'`
            
            #new function: statistic category quantity
            echo ${category} >>  category.txt
            
            # some App_name is hard to filter out from tables due to special format.
            # I must hardcore it.

            if [ "${app_id}" == "1pbIfwzCFmZM6rwzEVvA" ];then
                app_name="Maps"
            elif [ "${app_id}" == "W7QWTY9dVXxpsJ2whbxk" ];then
                app_name="Twitter"
            elif [ "${app_id}" == "6x6P4Ap7oCIzOW10hBpm" ];then
                app_name="YouTube"
            elif [ "${app_id}" == "oRD8oeYmeYg4fLIwkQPH" ];then
                app_name="Facebook"
            elif [ "${app_id}" == "vAQ_cypuhw7nt8cjRaHP" ];then
                app_name="Life"
            elif [ "${app_id}" == "ZL1czhKqL8sTAqZslZhA" ];then
                developer="JOYO_TECHNOLOG.LTD"
            elif [ "${app_id}" == "H27kQL2sVemarCQnFrF3" ];then
                developer="jiji"
            elif [ "${app_id}" == "-5yTeRojIPDKDsN5CxV_" ];then
                app_name="Shooting Star"
            elif [ "${app_id}" == "E6X0Dkol4yxRFMwlyByZ" ];then
                app_name="Bubble Shooter"
           
            fi
            #==================================================================================
            # New extension: Cu whitelist, with below lines we can get a cu-ID blacklist of each app(status 80)
            cu_col=`echo "${line_2}"|awk -F ',' '{print $5}'|grep '{'`
            if [ "${cu_col}x" != "x" ];then
                black_list=`echo ${line_2}|awk -F '[{}]' '{print $2}'|sed 's/,//g'|sed "s/'//g"`
                if [ "${black_list}" != "null" ];then
                	for black_id in `echo ${black_list}`;do
                    	echo ${black_id}
                	done > whitelist/blacklist_${app_id}.txt             

                    # Compare full_cu_id_list.txt and blacklist_${app_id}.txt
                    # calculate difference set to get whitelist id_whitelist_${app_id}.txt
                    cat whitelist/full_cu_id_list.txt whitelist/blacklist_${app_id}.txt|sort|uniq -u > whitelist/id_whitelist_${app_id}.txt
        
                    # calculate cu_whitelist_${app_id}  and module_whitelist_${app_id} from id_whitelist_${app_id}.txt
                    for white_id in `cat whitelist/id_whitelist_${app_id}.txt`;do
                        white_cu=`echo ${id2cu[$white_id]}`
                        white_module=`echo ${id2module[$white_id]}` 
                        echo ${white_module} >> whitelist/white_module_${app_id}.txt
                    done
        
                    # uniq white-module_${app_id}.txt remove the duplicate lines
                    cat whitelist/white_module_${app_id}.txt|sort|uniq > whitelist/white_module_2_${app_id}.txt
        
                    # format white_module_2_${app_id}.txt to adjust ajax_app json
                    # count is used to limit the white_list json fomate
                    count=0
                    for module in `cat whitelist/white_module_2_${app_id}.txt`;do
                        let count=count+1
                        if [ ${count} -eq 1 ];then
                            echo -n ${module} > whitelist/whitemodule_${app_id}.txt
                        else
                            echo -n "<br/>${module}" >> whitelist/whitemodule_${app_id}.txt
                        fi
                    done
                    white_module=`cat whitelist/whitemodule_${app_id}.txt`
                
                # if black_list=null, means no curef data (no blacklist),so :
                else
                    white_module="No blacklist for this App"
                fi    
            # if cu_col doesn't contain {}, means no curef data (no blacklist),so :      
            else
                white_module="No blacklist for this App"
                                      
            fi
        fi
    
    # if code != 80, it is not a published app, ignore.    
    else
        continue
    fi

    let num=num+1

# extension detail of table show app: display the history app versions
# I need to maintain a file here which contains history data
# the content like this:
#1.0: 2019/1/1 publish
#1.1: 2019/1/2 publish
#1.2: 2019/1/3 publish
    
    last_ver=`cat version_history/${app_id}.history|awk -F '[>:]' '{print $(NF-1)}'`
    if [ "${last_ver}" != "${version}" ];then
    # if found new version, backup all the directory,only backup once in the loop.
       let back_version=back_version+1
       if [ ${back_version} -eq 1 ];then
           echo " back_version is ${back_version}"
           tar -cjf ./version_history/version_history_${today2}.tar.bz2 ./version_history/*.history
           [ $? -eq 0 ]&& echo "backup version history complete" || echo "backup version history failed"
       fi
        echo "New version is published for ${app_name}-${app_id}."
    # add new version record to the version history file
        echo -n "<br/>${version}: ${update_date}" >> version_history/${app_id}.history
    
    else
        echo "No new version for ${app_name}-${app_id}."
        sleep 0.01
    fi

    # so the version history column should be:
    version_history=`cat version_history/${app_id}.history`
    # Get publish_date
    publish_date=`cat version_history/${app_id}.history|awk '{print $NF}'`
    
    echo ${app_id} >> ./manifest/app_id.txt
    ajax_app >> data.json
done


# new function: statistic category
cat category.txt|sort|uniq -c|sed 's/\s\+/:/g'|sort -r -n -k 2 -t : > category2quantity.txt
# Generate a map, key is "category",value is quantity
echo -n "{" > category2quantity.map
for line in `cat category2quantity.txt`;do
	quantity=`echo ${line}|awk -F ':' '{print $2}'`
        category=`echo ${line}|awk -F ':' '{print $3}'`
        echo -n "\"${category}\":" >> category2quantity.map
        echo -n "${quantity}, " >> category2quantity.map
done
# delete the last , 
sed -i 's/, $//g' category2quantity.map
echo -n "}" >> category2quantity.map
 

# Save the 2 values into a file
echo ${today} > table_head/today.txt
echo ${num} > table_head/num.txt

# delete the last ","
sed -i '$s/,//g' data.json
echo "  ]" >> data.json
echo "}" >> data.json
echo "====Ajax generated completed===="

#Copy Ajax to django server
ajax_dir="/data/tools/repository/nginx/html/app/static/kaios_app/datatables"
ajax_curef_dir="/data/tools/repository/nginx/html/app/static/kaios_app/datatables"
app_table="/data/tools/repository/nginx/html/app/table.html"
curef_table='/data/tools/repository/nginx/html/app/curef.html'
# copy app_summary to server for the "search uploader" api
scp data.json curef.json app_summary.csv kai-user@10.81.74.17:./

ssh kai-user@10.81.74.17 "sudo su -c ' cd ${ajax_dir} &&  mv data.json data.json_${today} && mv curef.json curef.json_${today}; mv /home/kai-user/data.json /home/kai-user/curef.json ${ajax_dir}/'"
[ $? -eq 0 ] && echo "Copied app_json and curef_json to Django server"

# Replace the Today and NUMBER key work in table.html
ssh kai-user@10.81.74.17 "sudo sed -i 's/${old_date}/${today}/;s/${old_num}/${num}/g' ${app_table} ${curef_table}"
[ $? -eq 0 ] && echo "Number and Date replaced" || echo "Number and Date replace failed"

