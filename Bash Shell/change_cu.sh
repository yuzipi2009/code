#!/usr/bin/env bash
#!/bin/bash

declare -A cu2id

old_cu_file=$1
new_cu_file=$2

if [ "x" = "x$old_cu_file" ]; then
	echo "[ERROR] Missing old_cu_file input file as first parameter. Aborting ..."
	exit 1
fi

if [ "x" = "x$new_cu_file" ]; then
	echo "[ERROR] Missing new_cu_file input file as second parameter. Aborting ..."
	exit 2
fi

dos2unix $old_cu_file
dos2unix $new_cu_file

echo "The new curefs are the following"

for line in `cat $old_cu_file`
do
 	id=`echo $line | awk -F, '{ print $1 }'`
 	cu=`echo $line | awk -F, '{ print $2 }'`
        cu2id[$cu]=$id
done


for curef in `cat $new_cu_file`
do
     id=${cu2id[$curef]}

     if [ "x" = "x$id" ]; then
         echo "$curef"
     fi
done > ${cu_archive_dir}/new_cu.txt