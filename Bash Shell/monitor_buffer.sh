
#!/bin/bash


buffer_dir="/data/buffer/"
#warn=102400
#critical=204800


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

usage=`du -sk ${buffer_dir}|awk '{print $1}'`
usage_2=`du -sh ${buffer_dir}|awk '{print $1}'`

if [ $usage -lt  $warn ]; then
    echo "buffer_status OK. usage is $usage_2. | 'buffer_usage'=$usage"
    exit 0;
fi

if [ $usage -gt  $critical ]; then
    echo "buffer_status Critical. usage is $usage_2. | 'buffer_usage'=$usage"
    exit 2;
fi

if [ $usage -gt  $warn ]; then
    echo "buffer_status Warning. usage is $usage_2. | 'buffer_usage'=$usage"
    exit 1;
fi
