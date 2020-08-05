#!/usr/bin/env bash
#!/bin/bash

old_ifs=$IFS
IFS=$'\n'

# delte child_list column

cat cats.csv|cut -d ',' -f1,3,4,5,6,7,8,9,10,11 > cat2.csv

head -1 cat2.csv > cats3.csv
for line in `cat cat2.csv`;do
	static=`echo $line|awk -F, '{print $5}'`
	if [ $static == "False" ];then
		echo "Found Flase static"
		echo $line >> cats3.csv
	fi
done

#delete the 3,4,5 column

cut -d ',' -f1,2,3,7,8,9,10 cats3.csv > cats4.csv

#insert a new cloumn
#generate a clumn which will be inserted into cats4.csv
cat /dev/null > type.txt
for i in `cat cats4.csv`;do
	echo 3 >> type.txt
done

paste -d ',' <(cut -d ',' -f-6 cats4.csv) type.txt <(cut -d ',' -f7- cats4.csv) > cats5.csv

# change the header
sed -i '1s/3/type/g' cats5.csv
IFS=$old_ifs