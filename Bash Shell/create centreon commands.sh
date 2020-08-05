#!/usr/bin/env bash
centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'notify-by-slack;/bin/sh -c '/usr/local/bin/slack_nagios.sh $NOTIFICATIONTYPE$ $SERVICESTATE$ $HOSTNAME$ $HOSTSTATE$ $SERVICEDESC$ $HOSTALIAS$ $HOSTADDRESS$ $DATE$ $SERVICEOUTPUT$ $NOTIFICATIONTYPE$ $HOSTALIAS$'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'Check_CPU;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_cpu -a $ARG1$ $ARG2$'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'Check_Memory;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_mem -a $ARG1$ $ARG2$'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'Check_net_traffic;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_net_traffic -a $ARG1$ $ARG2$ $ARG3$'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'Check_IOSTAT;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_iostat -a $ARG1$'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'Check_free_disk;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_free_disk -a $ARG1$ $ARG2$ $ARG3$'
'
centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_haproxy_stats;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_haproxy_stats'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_gnats_stats;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_gnats_stats'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_app_store;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_kaios_app_store'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_download;$USER2$/check_nrpe -H $HOSTADDRESS$ -t 120 -c check_kaios_download'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_login;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_kaios_login'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_rat_app_store;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_kaios_rat_app_store'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_rat_download;$USER2$/check_nrpe -H $HOSTADDRESS$ -t 120 -c check_kaios_rat_download'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_rat_login;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_kaios_rat_login'

centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_kaios_refresh;$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_kaios_refresh'
centreon -u admin -p 'admin!@#' -0 CMD -a ADD -v 'check_certificate;/bin/sh -c '$USER2$/check_nrpe -H $HOSTADDRESS$ -c check_certificate -a $ARG1$ $ARG2$ $ARG3$ $ARG4$'
