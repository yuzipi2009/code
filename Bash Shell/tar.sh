#!/usr/bin/env bash
#!/bin/bash

res_dir=`dirname $0`
cur_dir=`cd ${res_dir};pwd`
abs_dir=${cur_dir}

#ls ${abs_dir}|egrep -v 'tar|keys'

#exit
for i in `ls ${abs_dir}|egrep -v 'keys|tar'`
  do
	module=`echo ${i}|awk -F '-' '{print $1}'`
	tar -cjf ${module}.tar.bz2 ${i}
	[ $? -eq 0 ]&& echo "${module} success"||{
        echo "failed"
        break
        }
        #sudo rm -rf ${i}
done