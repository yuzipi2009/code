#!/bin/bash

for id in `cat ./id.txt`;do
    # id is the apps which can't be deleted
    line=`grep $id ./version2.csv`
    if [ "${line}x" != "x" ];then
    echo "${line}" >> version3.csv
    fi
done
echo "Finished version"

for id in `cat ./id.txt`;do
    # id is the apps which can't be deleted
    line=`grep $id ./summary2.csv`
    if [ "${line}x" != "x" ];then
    echo "${line}" >> summary3.csv
    fi
done
echo "Finished summary"

for id in `cat ./id.txt`;do
    # id is the apps which can't be deleted
    line=`grep $id ./app2.csv`
    if [ "${line}x" != "x" ];then
    echo "${line}" >> app3.csv
    fi
done
echo "Finished app"