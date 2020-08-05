
#!/bin/bash

#run as root

QUERY="select p.id as prohectId,p.name as projectName,c.name as odmName from operators.projects as p left join operators.customers as c on p.odm_id = c.id;"
json_dir="/data/tools/repository/nginx/html/app/static/kaios_app/datatables/odm_project"

odm_project () {
   echo "    {"
   echo "      \"Project_id\": \"${projectId}\"",
   echo "      \"Odm_name\": \"${odmName}\"",
   echo "      \"Project_name\": \"${projectName}\""
   echo "    },"
}

mysql -e "${QUERY}"|sed 's/ /_/g'|sed '1d' > /tmp/foo.txt

OLD_IFS=$IFS
IFS=$'\n'
cat /dev/null > ${json_dir}/data.json

echo "{" >> ${json_dir}/data.json
echo "  \"data\": [" >> ${json_dir}/data.json

for line in `cat /tmp/foo.txt`;do
    projectId=`echo ${line}|awk '{print $1}'`
    projectName=`echo ${line}|awk '{print $2}'`
    odmName=`echo ${line}|awk '{print $3}'`
    odm_project >> ${json_dir}/data.json
done

IFS=$OLD_IFS

# delete the last ","
cd ${json_dir} && \
sed -i '$s/,//g' data.json && \
echo "  ]" >> data.json && \
echo "}" >> data.json && \
echo "====Ajax generated completed===="