#!/bin/bash

LOG="/data/tools/repository/signapp/signapp.log"
error="NATS Disconnection detected"




[ -f ${LOG} ] ||



#warn=10
#critical=50

while test -n "$1";do
	case $1 in

	  -w)
	    warn=$2
            shift
            ;;

          -c)
	    critical=$2
            shift
            ;;

	esac
        shift
done

count=`grep "${error}"  ${LOG}`

if [ ! -f  ${LOG} ]; then
echo "SA Log missed | 'error_count'='error'"
    exit 2;
fi

if [ $count -lt  $warn ]; then
    echo "SA to NATS OK. $count errors | 'error_count'=$count"
    exit 0;
fi

if [ $count -gt  $warn ] && [ $count -lt  $critical ] ; then
    echo "SA to NATS Waringing. $count errors | 'error_count'=$count"
    exit 1;
fi

if [ $count -gt  $critical ]; then
    echo "SA to NATS Critical. $count errors | 'error_count'=$count"
    exit 2;
fi

