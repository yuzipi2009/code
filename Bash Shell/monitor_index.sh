#!/bin/bash


today=`date +%Y.%m.%d`
file=`mktemp /tmp/test.XXXX`

#judge argument
# 2nd argument must be a number 0 1 2
function judge_argu2 () {

if ! [[  "$argu"  =~ ^[0-2]$ ]];then
	echo "2nd argument must be a number 0 or 1 or 2"
        exit 10
#else
#	echo GOOD
fi
}

while test -n "$1";do
	case $1 in

          -n)
            normal_level=$2
            argu=$normal_level
            judge_argu2

            shift
            ;;

	  -w)
	    warn_level=$2
            argu=$warn_level
            judge_argu2
            shift
            ;;

          -c)
	    critical_level=$2
            argu=$critical_level
            judge_argu2
            shift
            ;;

	esac
        shift
done

if [ "$normal_level" == "" ]; then
    echo "No Normal Level Specified"
    exit 3;
fi



if [ "$warn_level" == "" ]; then
    echo "No Warning Level Specified"
    exit 3;
fi

if [ "$critical_level" == "" ]; then
    echo "No Critical Level Specified"
    exit 3;
fi


# Get index status
curl -XGET localhost:9200/_cat/indices?v  > $file 2>/dev/null

if [ $? -ne 0 ]; then
    echo "index_status Critical. red. | 'index status'=2"
    exit 2;
fi

# Get the index status of today
status=`cat  $file |grep ${today}|awk '{print $1}'`

if [ "$status" == "green" ];then
    #value="${green}OK"
     value=0
fi

if [ "$status" == "yellow" ];then
    #value="${yellow}Waring"
     value=1
fi

if [ "$status" == "red" ];then
    #value="${red}Critical"
     value=2
fi

if [ "$value" -eq "$normal_level" ]; then
    echo "index_status OK. $status. | 'index status'=$value"
    exit 0;
fi

if [ "$value" -eq "$warn_level" ]; then
    echo "index_status Warning. $status. | 'index status'=$value"
    exit 1;
fi

if [ "$value" -eq "$critical_level" ]; then
    echo "index_status Critical. $status. | 'index status'=$value"
    exit 2;
fi


rm -rf ${file}