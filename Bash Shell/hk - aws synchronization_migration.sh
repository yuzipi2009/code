#!/usr/bin/env bash

#This script will run on HK-DM(DMH)

#AWS test DM
DMA="54.160.226.113"

#AWS production server
#DMP="54.173.122.83"

#HK production DM
DMH="223.119.56.175"

aws_user="iot-user"
mysql_pwd="Admin01ME!"
hk_dn="sh.kaiostech.com"
hk_ha="223.119.56.169"
slave_user="slave2018"
slave_pwd="password"
mysql_dir="/data/tools/repository/mysql-*"


#1 The first part is to pre-check Mysql master-slave status and configure synchronization
#1.1 Configure master firstly, DMA is master for test case, DMP is master in real migration case
#1.1.1 Check if exist mysql bin PATH
date=`date "+%Y-%m-%d %H:%M"`
echo -e "Part1: Pre-check Mysql Master DMA and Configure schronization\n${date}\n"

which mysql
[ $? -ne 0 ] &&  {
echo "[Error] (1/7)No mysql PATH, please add it for DMH local user, Aborting."
exit
} ||
echo "(1/7) Mysql PATH check OK"


ssh "${aws_user}"@"${DMA}" "which mysql"
[ $? -ne 0 ] &&  {
echo "[Error] (1/7)No mysql PATH, please add it for DMA local user, Aborting."
exit
}


#1.1.1 Create replication user for slave
ssh "${aws_user}"@"${DMA}" "mysql -uroot -p${mysql_pwd} -e '
delete from mysql.user where user='\''${slave_user}'\'';
grant replication slave on *.* to ${slave_user}@${DMH} identified by '\''${slave_pwd}'\'';
flush privileges;'" 2>/dev/null

[ $? -eq 0 ] && echo "(2/7)Replication user create OK" || {
echo "[Error] (2/7)Create replcation user failed, Aborting."
exit
}


#1.1.2 Show master status, record the bin-log position
master_status=`ssh "${aws_user}"@"${DMA}" "mysql -uroot -p${mysql_pwd} -e 'show master status'" 2>/dev/null`

bin_log=`echo "${master_status}"|sed '1d'|awk '{print $1}'`
bin_position=`echo "${master_status}"|sed '1d'|awk '{print $2}'`\

if [ "x${bin_log}" = "x" ];then
	echo "[Error] (3/7)you must enbale bin-log for Mysql master, Aborting"  && exit
else
	echo "(3/7)DMA bin-log check OK"
fi



#1.2 Configure Mysql slave, DMH is slave for both test and real case
echo "Start to pre-configure Mysql slave DMH"

#1.2.1 Test access to master with the above created account
# Flush hosts to avoid too many connection error
ssh "${aws_user}"@"${DMA}" "mysqladmin -uroot -p${mysql_pwd} flush-hosts" 2>/dev/null
mysqladmin -uroot -p${mysql_pwd} flush-hosts 2>/dev/null

mysql -u"${slave_user}" -h"${DMA}" -p"${slave_pwd}" -e 'exit' 2>/dev/null
[ $? -eq 0 ] && echo "(4/7)Slave remote access OK" || {
echo "[Error] (4/7)Remote access failed, Aborting."
exit
}


#1.2.2 Change master bin-log info

mysql -uroot -p${mysql_pwd} -e "
stop slave;
change master to
master_host='"${DMA}"',
master_port=3306,
master_user='"${slave_user}"',
master_password='"${slave_pwd}"',
master_log_file='"${bin_log}"',
master_log_pos=${bin_position};
start slave;" 2>/dev/null

[ $? -eq 0 ] && echo "(5/7)Change master bin-log OK" || {
echo "[Error] (5/7)Slave change master bin-log failed, Aborting."
exit
}
# Wait for slave IO startup
sleep 5

#1.2.3 Check slave status, IO and SQL running should be YES, Fail if NO or empty
slave_status=`mysql -uroot -p"${mysql_pwd}" -e "show slave status\G" 2>/dev/null`
io_status=`echo "${slave_status}"|grep -w 'Slave_IO_Running' |awk '{print $2}'`
sql_status=`echo "${slave_status}"|grep -w 'Slave_SQL_Running'|awk '{print $2}'`
log_file=`echo "${slave_status}"|grep -w 'Master_Log_File'|awk '{print $2}'`
log_pos=`echo "${slave_status}"|grep -w 'Read_Master_Log_Pos'|awk '{print $2}'`


if [ "x${slave_status}" = "x" ];then
	echo "[Error] No slave status output, Aborting." && exit
elif [ "${io_status}" = "Yes" ] && [ "${sql_status}" = "Yes" ];then
	echo "(6/7)Check slave IO/SQL running status OK"
else
	echo "[Error] (6/7)Slave IO/SQL running status should be 'YeS', Aborting." && exit
fi

#1.2.4 Check master and slave server-id, this id is uniq, they shouldn't be the same
conf_a=`ssh "${aws_user}"@"${DMA}" "grep -w 'server_id' ${mysql_dir}/my.cnf"`
conf_h=`grep -w 'server_id' ${mysql_dir}/my.cnf`
id_a=`echo "${conf_a}"|grep -v '#'|awk -F '=' '{print $2}'`
id_h=`echo "${conf_h}"|grep -v '#'|awk -F '=' '{print $2}'`

if [ "x${id_a}" != "x" ] && [ "x${id_h}" != "x" ] && [ "${id_a}" != "${id_h}" ];then
	echo "(7/7)Server ID check OK"
else
	echo -e "[Error] (7/7)Server ID check failed, please check, Aborting.\nDMA_ID:${id_a}\nDMH_ID:${id_h}\n"
fi

echo -e "Part1 pre-check/configure mysql master-slave complete\n"

#2.The second part is to export DMA gotu database and import it to DMH
echo "Start Part2: export and import gotu database"
#2.1 Mysqldump - export gotu database
echo -e "\n!!!!!!!!!!!!!!!!!!!!!!!!!!!impotrt NOW!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
ssh "${aws_user}"@"${DMA}" "mysqldump -uroot -p"${mysql_pwd}" --single-transaction --master-data gotu|gzip >/tmp/gotu2018.sql.gz" 2>/dev/null
[ $? -eq 0 ] && echo "(1/3) Master mysqldump OK" || {
echo "[Error] Mysqldump failed, Aborting."
exit
}


#2.2 DMH Fetch gotu2018.sql
scp "${aws_user}"@"${DMA}":/tmp/gotu2018.sql.gz /tmp
gunzip /tmp/gotu2018.sql.gz

[ $? -eq 0 ] && echo "Fetched database sql file OK" || {
echo "[Error] Fetched database sql file failed, Aborting."
exit
}

sql_size=`du -sh /tmp/gotu2018.sql|awk '{print $1}'`
echo "The sql size is ${sql_size}"

#2.3 Import gotu2018.sql
mysql -uroot -p${mysql_pwd} -e "
stop slave;
drop database if exists gotu;
create database gotu;
use gotu;
source /tmp/gotu2018.sql;
start slave;" 2>/dev/null

[ $? -eq 0 ] && echo "(2/3) Slave import SQL OK" || {
echo "[Error] Slave import SQL failed, Aborting."
exit
}

sleep 5
#2.4 Check slave status to verify it is running
slave_status_2=`mysql -uroot -p${mysql_pwd} -e "show slave status\G" 2>/dev/null`
io_status_2=`echo "${slave_status_2}"|grep -w 'Slave_IO_Running' |awk '{print $2}'`
sql_status_2=`echo "${slave_status_2}"|grep -w 'Slave_SQL_Running'|awk '{print $2}'`
log_file_2=`echo "${slave_status_2}"|grep -w 'Master_Log_File'|awk '{print $2}'`
log_pos_2=`echo "${slave_status_2}"|grep -w 'Read_Master_Log_Pos'|awk '{print $2}'`

if [ "x${slave_status_2}" = "x" ];then
	echo "[Error] No slave status output after import, Aborting." && exit
elif [ "${io_status_2}" = "Yes" ] && [ "${sql_status_2}" = "Yes" ];then
	echo -e "(3/3)Slave IO/SQL running status OK after import\n"
else
	echo "[Error] Slave IO/SQL running status should be 'Yes' after import, Aborting." && exit
fi

#2.5 Check if the bin position is changed
echo -e "Before import:\nbin-log:${log_file}\nbin-position:${log_pos}\n"
echo -e "After import:\nbin-log:${log_file_2}\nbin-position:${log_pos_2}\n"
date_2=`date "+%Y-%m-%d %H:%M"`
echo -e "Data migration from DMA to DMH complete\n${date_2}"