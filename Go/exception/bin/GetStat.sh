#!/bin/bash

user=$1
gk=$2
node=$3
layer=$4

ssh $user@$gk "ssh $node \"[ -f /data/var/cumulis_${layer}.out ] && stat -t /data/var/cumulis_${layer}.out\""


