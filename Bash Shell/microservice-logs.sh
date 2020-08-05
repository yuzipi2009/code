#!/usr/bin/env bash
#!/bin/bash

# Declare an array of string with type
declare -a MicroservicesName=("content-microservice" "network-test-microservice" "currency-microservice" "auth-microservice" )

# Iterate the string array using for loop
if [ $1 ]; then
    # remove folder if its exists
    if [ -d "$1" ]; then
        rm -rf $1
    fi

    # create folder
    mkdir $1

    # save logs
    for val in ${MicroservicesName[@]}; do
        docker cp $val:../logs $1/$val
        docker exec -it $val sh -c "rm -rf ../logs/*"
        echo "$val logs was created successfuly"
    done
else
    echo "You must pass the path where logs will be saved"
    echo "eg: ./microservice-logs.sh path/to/save/logs"
    exit 1