
#!/bin/bash



CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"
env="kaicloud_test"

#download table

#:<<!
${CQLSH} -e "copy ${env}.app_version to '/tmp/filter/app_version.csv' with header=true and null='<null>'"
[ $? -eq 0 ] && \
${CQLSH} -e "copy ${env}.app_2 to '/tmp/filter/app_2.csv' with header=true and null='<null>'"
[ $? -eq 0 ] && \
${CQLSH} -e "copy ${env}.app_summary to '/tmp/filter/app_summary.csv' with header=true and null='<null>'"

[ $? -eq 0 ] && echo "Downloaded 3 tables to /tmp/filter" || echo "Download tables failed"
#!

cd /tmp/filter

#filter
tablelist="app_version app_summary app_2"
appfile="/tmp/filter/app.txt"

if [ ! -f ${appfile} ] || [ ! -f 'app_version.csv' ] || [ ! -f 'app_summary.csv' ] || [ ! -f 'app_2.csv' ];then
    echo "File not ready"
    exit
fi

PLACEHOLDE

for file in ${tablelist};do



    echo "Start to deal with ${file}.csv"


    #refreh the ouput file
    cat "/dev/null" > ${file}_need_delete.csv
    #echo header to ${file}_keep.csv
    head -1  ${file}.csv > ${file}_keep.csv
    #remove the header to compare, because the the header will not keep in 1st line afet sort|uniq command
    sed -i '1d' ${file}.csv

    # ${file}_need_delete.csv is the file which contains the app will be delete
    # ${file}_keep.csv is the file contains the app will be kept
    for app in `cat ${appfile}`;do
        out=`grep ${app} ${file}.csv`
        if [ "x" != "x${out}" ];then
            echo ${out} >> ${file}_need_delete.csv
            echo "${app} -> Found!"
        else
            echo "Not Matched!"
        fi
    done
    cat ${file}_need_delete.csv ${file}.csv|sort|uniq -u >> ${file}_keep.csv
    [ $? -eq 0 ]  && echo "Generate ${file}_keep.csv"
    sleep 3
done

#===============below is to get artifact=================="
grep -Po "/\S/\S+.?png|/\S/\S+.?zip" app_version_keep.csv > artifact.txt


#Blow part is to operate mc client, run in minio user


MC="/home/minio/bin/mc"
bucket="private public"
cd ~/ && cd artifact && echo "accessed to artifact dir" || echo "access to artifact failed"
[ ! -f artifact.txt ] && {
echo "artifact.txt not ready"
exit
}

for file in `cat artifact.txt`;do
    for b in ${bucket};do
        ${MC} cp --recursive s3/${b}/${file} ${b}/${file}
        if [ $? -eq 0 ];then
            echo "Saved ${b}/${file}"
        fi
    done
done

echo "Saved ALl"



