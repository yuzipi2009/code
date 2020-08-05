#!/bin/sh

thedate=`date +'%Y%m%d_%H%M'`
backup_folder_name=/data/tools/repository/empowerthings/logs/${thedate}

mkdir -p ${backup_folder_name}

#find /data/var -maxdepth 1 -type f -name \*.log.[0-9]\* -ctime +1 -exec mv -f {} ${backup_folder_name} \;
find /data/tools/repository/empowerthings -maxdepth 1 -type f -name \*.log.[0-9]\* -cmin +30 -exec mv -f {} ${backup_folder_name} \;

amount_of_files=`find ${backup_folder_name} -type f | wc -l`

if [ ${amount_of_files} -eq 0 ]; then
   # echo "Deleting empty folder ${backup_folder_name}"
    rm -Rf ${backup_folder_name}
else
    xz ${backup_folder_name}/*.log.[0-9]*
fi

#find /data/var -maxdepth 1 -type f -name \*.log.[0-9]\* -ctime +1 -exec rm -f {} \;

find /data/tools/repository/empowerthings/logs -type d -ctime +21 -exec rm -Rf {} \;