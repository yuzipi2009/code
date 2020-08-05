#!/bin/bash

echo "Processing date : $1"

for d in /data/logs/$1_*/; do
  if [ -d "$d" ]; then
        echo "Process file : $d"
  	xzgrep /v3.0/apps/metrics $d/* | grep '==METRICS' | awk '{print substr($1i,67,10) "," $2 "," $7 "," $8 "," $11 "," $12 "," $13 "," $14}' > $1_request.csv
    	xzgrep 'Restoring session' $d/* > $1_detail.out
  fi
done

python convert_json.py $1

rm $1_detail.out

exit 0