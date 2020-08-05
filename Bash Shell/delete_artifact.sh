#!/bin/bash
# run on minio nodes with minio user

for dir in `cat ./zip.txt`;do
    /home/minio/bin/mc rm s3/public/$dir
    if [ $? -ne 0 ];then
        echo "Error happened"
        exit
    fi
done
echo "FINISH Cleaning ZIP"

for dir in `cat ./icon.txt`;do
    /home/minio/bin/mc rm s3/public/$dir
    if [ $? -ne 0 ];then
        echo "Error happened"
        exit
    fi
done
echo "FINISH Cleaning ICON"

#Access to minio to delete
#/home/minio/bin/mc rm s3/public/d/nALVzzDBEX7XwHOnfE7crPluWeZm6tudp966X7/ICON_IMAGE.png