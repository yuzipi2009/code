#!/usr/bin/env bash
#!/bin/sh

##################################################################################
# This script will just generate the slot list between {from} and {to} included
# so that it can be used with the 'cluster addslots' directive.

from=$1
to=$2

if [ "x" = "x$from" ]; then
    echo "[ERROR] missing {from} and {to} arguments (integer between 0 and 16383)."
    exit 1
fi

if [ "x" = "x$to" ]; then
    echo "[ERROR] missing {to} arguments (integer between 0 and 16383)."
    exit 2
fi

re='^[0-9]+$'
if ! [[ $from =~ $re ]] ; then
    echo "[ERROR] {from} should be an integer between 0 and 16382."
    exit 3
fi

if ! [[ $to =~ $re ]] ; then
    echo "[ERROR] {to} should be an integer between 1 and 16383."
    exit 3
fi

if [ $from -lt 0 ];  then
    echo "[ERROR] {from} should be greater or equal than 0 and lower than 16383 ... "
    exit 5
fi

if [ $from -ge 16383 ];  then
    echo "[ERROR] {from} should be lower than 16383 ... "
    exit 5
fi

if [ $to -gt 16383 ];  then
    echo "[ERROR] {to} should be lower or equal than 16383 ... "
    exit 4
fi

if [ $from -ge $to ];  then
    echo "[ERROR] {from} should be lower than {to} ... "
    exit 4
fi

let "i=$from"

while [ /bin/true ];
do
    echo -n "$i "
    let "i=$i+1"
    if [ $i -gt $to ]; then
        break
    fi
done

echo

========================================================================
[root@k2-hk1-rema-a-001 src]# ./redis_gen_slots.sh 0 100
0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100