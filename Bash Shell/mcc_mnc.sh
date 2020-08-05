#!/bin/bash
# get code json

jq -c '.[]|select (.type != "Test")|select (.countryName != null)| select (.status == "Operational")|select (.notes|tostring|contains ("testing") or contains ("test") or contains ("Test")|not)|{brand,mcc,mnc,notes,operator}' mcc-mnc-list.json > code.txt

old_ifs=`${IFS}`
# get each field

IFS=@
for line_1 in `cat code.txt`;do
    line=`echo ${line_1}|sed 's/[{}"]//g'`
    brand=`echo ${line}|awk -F '[,;]' '{print $2}'`
    mcc=`echo ${line}|awk -F '[,;]' '{print $4}'`
    mnc=`echo ${line}|awk -F '[,;]' '{print $6}'`
    notes=`echo ${line}|awk -F '[,;]' '{print $8}'`
    operator=`echo ${line}|awk -F '[,;]' '{print $10}'`
    code=$mcc$mnc
    if ! [[ $code =~ ^[0-9]$ ]];then
        echo "wrong code is $code"
    fi

#  filter out the new code and echo new line to cassandra table
    for line_2 in `cat hni.csv`;do
        check=`grep $code ${line_2}`
        if [ "x" == "x${check}" ];then
            echo "Already contain this code-${code}"
        else
            echo "This is a new code: ${code}"
        fi
    done
done