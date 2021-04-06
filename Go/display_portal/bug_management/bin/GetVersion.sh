#!/bin/bash

user=$1
gk=$2
node=$3
layer=$4

ssh $user@$gk "ssh $node \"cd /data/var;ls -l bin|grep -Po 'empowerthings-\S+\d'|sed 's/n//g'\""



