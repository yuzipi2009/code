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
   echo "      \"App_Name\": \"${app_name}\","
   echo "      \"Description\": \"${description}\"",
   echo "      \"Category\": \"${category}\","
   echo "    },"
}


#:<<!
# Fech summary and version table and copy to cassandra node

ssh ${user}@${prod_gk} "ssh  ${prod_cass} \"sudo su - cassadmin -c \\\"rm -rf /tmp/app_2.csv ; ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.app_2 (category,description,display,status,type) to '/tmp/app_2.csv' with header=false and null='<null>' \\\\\\\" && chmod 755 /tmp/app_2.csv \\\"\""

# Copy to GK5
[[ $? -eq 0 ]] && ssh ${user}@${prod_gk} "rm -rf /tmp/app_2.csv ; scp ${prod_cass}:\"/tmp/app_2.csv \" /tmp" || { echo "Copy app_2 from cassandra failed, Aborting";exit;}

# Copy to local
[[ $? -eq 0 ]] && rm -rf app_2.csv ; scp ${user}@${prod_gk}:"/tmp/app_2.csv" ./ && echo "Fetch app_2 table to local.. OK"|| { echo "Copy app_2 from K5-GK failed, Aborting";exit;}




# Basic method:
#1) Get App_id , developer, status_code, update_date, version by loop app_versionx.csv
#2) Get App_name and category from app_summaryx.csv by filter the app_id
#3) only status=80 is valid

# back_up old datax.json and create the head of new file

echo "{" >> datax.json
echo "  \"data\": [" >> datax.json

#Get the former data of date and number
old_date=`cat table_head/todayx.txt`
old_num=`cat table_head/numx.txt`
echo "====Today is ${today}===="

OLD_IFS=$IFS
IFS=$'\n'
num=0

for line in `cat app_2.csv`;do

    #Get Status
    status_code=`echo ${line}|awk -F ',' '{print $(NF-1)}'`

    if [ ${status_code} -eq 80 ];then
        #Get Category
        categoty=`echo ${line}|awk -F ',' '{print $1}'`
        #Get description
        description=`echo ${line}|awk -F, '{$NF=null;$1=null;$(NF-2)=null;$(NF-1)=null;print $0}'`
        #Get Version
        app_name=`echo ${line}|awk -F ',' '{print $(NF-2)}'`
        #Get type
        type=`echo ${line}|awk -F ',' '{print $NF}'`
    # if code != 80, it is not a published app, ignore.
    else
        continue
    fi
    let num=num+1
    ajax_app >> datax.json
done
IFS=$OLD_IFS



# Save the 2 values into a file
echo ${today} > table_head/todayx.txt
echo ${num} > table_head/numx.txt

# delete the last ","
sed -i '$s/,//g' datax.json
echo "  ]" >> datax.json
echo "}" >> datax.json
echo "====Ajax generated completed===="

#Copy Ajax to django server
ajax_dir="/data/tools/repository/nginx/html/app/static/kaios_app/datatables"
app_table="/data/tools/repository/nginx/html/app/table2.html"
# copy app_summary to server for the "search uploader" api
scp datax.json curef.json app_summaryx.csv kai-user@10.81.74.17:./

ssh kai-user@10.81.74.17 "sudo su -c ' cd ${ajax_dir} && mv /home/kai-user/datax.json ${ajax_dir}/'"
[ $? -eq 0 ] && echo "Copied app_json and curef_json to Django server"

# Replace the Today and NUMBER key work in table.html
ssh kai-user@10.81.74.17 "sudo sed -i 's/${old_date}/${today}/;s/${old_num}/${num}/g' ${app_table}"
[ $? -eq 0 ] && echo "Number and Date replaced" || echo "Number and Date replace failed"
