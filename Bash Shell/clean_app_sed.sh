
#!/bin/bash



CQLSH="/data/tools/repository/apache-cassandra/bin/cqlsh"
env="kaicloud_stage"

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


#Get the full app_id table
OLD_IFS=$IFS
IFS=$'\n'

cat /dev/null > full_app_id.txt
for line in `cat app_version.csv`;do
    app_id=`echo ${line}|awk '{print $1}'`
    echo ${app_id} >> full_app_id.txt
done

cat  full_app_id.txt ${appfile} |sort|uniq -u > appid_will_delete.txt

#=================

for file in ${tablelist};do


    echo "Start to deal with ${file}.csv"

    #backup the source file
    cp -a ${file}.csv ${file}_backup.csv

    for app in `cat appid_will_delete.txt`;do
        # it is better to only modify the source csv file
        # Because it will hava some problems when copy to cassandra if you generate a new csv
        # so I just delete lines with sed command instead of > a new file
        # so there will not generate any midile temp files
        sed -i "s/${app}/d" ${file}.csv
    done
    sleep 2
done

#===============below is to get artifact=================="
grep -Po "/\S/\S+.?png|/\S/\S+.?zip" app_version.csv > artifact.txt


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

        # the uncomment cmd is wrong, it will save artifact like this:
        #protected/t/V8j6HK5py8nTJYiFyTkcWdXsiwBCDu22-IzPi5/1.0.1_APP_ZIP_FILE.zip/protected/t/V8j6HK5py8nTJYiFyTkcWdXsiwBCDu22-IzPi5/1.0.1_APP_ZIP_FILE.zip
        #${MC} cp --recursive s3/${b}/${file} ${b}/${file}
        ${MC} cp --recursive s3/${b}/${file} ./
        if [ $? -eq 0 ];then
            echo "Saved ${b}/${file}"
        fi
    done
done

echo "Saved ALl"

:<<!
    find ./ -type f \( -name "*.zip" -o -name "*.png" \) |sed 's#^./##g'> fix_protect.path`
    #!/bin/bash

for i in `cat fix_protect.path`;do
	dir1=`echo $i|awk -F/ '{print $1}'`
	dir2=`echo $i|awk -F/ '{print $2}'`
        dir="${dir1}/${dir2}"
        #echo "$dir"
        #echo "$i"
	../../mc cp protected/$i s3/protected/$dir/
        #../../mc rm --recursive --force s3/protected/$dir
done


!


