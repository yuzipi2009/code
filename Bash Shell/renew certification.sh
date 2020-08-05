#!/bin/bash

## Yuxiao
## this script should be run on as iot-user@k1-na2-cert-a-001

# set variable

export certmgr_dir="/data/tools/repository/certmgr"
export cert_dir="/data/tools/repository/certmgr/var/certs"
export live_dir="/etc/letsencrypt/live"
export today=`date +%s`
export ha_dir="/data/tools/repository/haproxy"

## define ha nodes and nginx nodes
export dev_ha=(
172.31.26.237
)
# test env in in hk dc, and the ssh user should be kai-user
export test_ha=(
223.119.56.169
223.119.56.170
)

export stage_ha=(
34.195.148.152
)

export preprod_ha=(
52.207.188.202
18.210.214.123
)


export prod_ha=(
54.210.66.141
34.198.216.44
34.199.156.169
52.45.166.254
52.6.116.11
52.86.76.216
18.205.223.130
18.209.252.212
)

export kaios_ha=(
35.170.100.24
34.232.207.32
)

export k5_push_ha=(
34.206.195.150
34.194.206.58
)

export fota_ha=(
34.201.58.167
)

export dev_nginx=(
172.31.21.14
)

# stage_jenkins is actually on k4
export stage_nginx=(
52.3.190.31
)

export prod_nginx=(
52.201.80.21
)

export jiosit_ha=(
172.31.15.3
)

export t001_ha=(
172.31.90.137
)

export open_ha=(
52.70.113.166
)

# Functions
## Function: renew certification
function renew_cert()
{
cd ${certmgr_dir} && source ./prep.sh && \
./bin/dehydrated -f etc/$1/config.txt -c && \
./bin/bundle_cert.sh $1
}

## function: upload the cert to aws certification manager, only below DN should be uploaded:
## cdn.kaiostech.com; stage.kaiostech.com; preprod.kaiostech.com;prod.kaiostech.com; kaiostech.com
function upload_aws_arn()
{
cd ${certmgr_dir} && source ./prep.sh && \
./bin/update_aws_arn_cert.sh $1
}

## Function: kill old haproxy process

function kill_ha(){

pid_list=`sudo pidof haproxy`
for pid in ${pid_list};do
    sudo kill -15 ${pid}
done
}

## Function: copy pem files to haproxy and reload

function copy_pem_haproxy()
{

nodes_ha=("$@")
for host in "${nodes_ha[@]}";do

    # the ssh user of AWS servers should be iot-user always, but for test env,it is kai-user
    # backup combo.pem
    ssh ${user}@${host} "sudo su -c 'cd ${live_dir}/${DN} && cp combo.pem combo.pem_`date +%Y%m%d`' " && \
    # copy new combo.pem
    scp ${cert_dir}/${DN}/combo.pem ${user}@${host}:~/ && \
    ssh ${user}@${host} "sudo su -c 'mv combo.pem ${live_dir}/${DN}/'" && \
    # check if haproxy has reload.sh, if yes, use reload , if not, kill-process,then use restart.sh
    ssh ${user}@${host} "sudo su -c 'cd ${ha_dir} && test -f ./sbin/reload-haproxy.sh && \
    ./sbin/reload-haproxy.sh || \
    { $(typeset -f kill_ha);kill_ha;sudo ./sbin/restart-haproxy.sh;}'"
    [[ $? -eq 0 ]] && echo "[OK] haproxy processes are restart successfully"||echo "[Failed] haproxy kill process or restart failed"

    #chech haproxy process set up or not after restart
    PID=`ssh ${user}@${host} "sudo pidof haproxy"`
    [[ $? -eq 0 ]] && [[ "${PID}x" != "${PID}" ]] &&
    echo "${url}:[SUCCEED], haproxy Process found after restart/reload" || \
    echo "${url}:[ERROR], NO haproxy Process found after restart/reload"

done
}

## Function: copy pem files to nginx and reload
function copy_pem_nginx()
{
nodes_nginx=("$@")
for host in "${nodes_nginx[@]}";do
    ssh ${user}@${host} "sudo su -c 'cd ${live_dir}/${DN} && cp combo.pem combo.pem_`date +%Y%m%d` && cp privkey.pem privkey.pem_`date +%Y%m%d`'" && \
    cd ${cert_dir}/${DN}/ && scp combo.pem privkey.pem ${user}@${host}:~/ && \
    ssh ${user}@${host} "sudo su -c 'mv combo.pem privkey.pem  ${live_dir}/${DN}/'" && \
    ssh ${user}@${host} "sudo /usr/sbin/nginx -s reload"
    [[ $? -eq 0 ]] && echo "[OK] Nginx reload succeed"||echo "[Failed] Nginx reload  failed"

    #chech haproxy process set up or not after restart
    PID=`ssh ${user}@${host} "sudo pidof nginx"`
    [[ "${PID}x" == "${PID}" ]] &&
    echo "${url}:[ERROR],NO nginx Process found after restart/reload" || \
    echo "${url}:[SUCCEED], nginx Process found after restart/reload"

done
}


#==========================================================================================================#

# Main
## execute prep.sh -> check_expire.sh -> compare due_date -> run renew.cert ot not
domain_record=`cd ${certmgr_dir} && ./bin/check_expire.sh|sed /Certificate/d`
echo "${domain_record}"|sed 's/\s\+/,/g' > domain_list.txt

echo -e "\n======================`date +"%Y-%m-%d %T"`=====================\n"

for line in `cat domain_list.txt`;do
    ##example: url=push.test.kaiostech.com; DN=test.kaiostech.com; host=push; domain=test
    export url=`echo "${line}"|awk -F "," '{print $1}'`
    export DN=`echo "${url}"|awk -F "." '{print $(NF-2)"."$(NF-1)"."$NF}'`
    ## the host contains service|api|auth|storage|origin|jenkins|push|dm
    host=`echo "${url}"|awk -F "." '{print $1}'`

    ## the domain should be test|stage|preprod|prod, if not,
    ## it should be production, like "api|services|storage.kaiostech.com"

    domain=`echo ${url}|awk -F "." '{print $(NF-2)}'`
    due_date=`echo "${line}"|awk -F "," '{print $NF}'|awk -F "-" '{print $3$1$2}'`
    due_date_s=`date -d ${due_date} +%s`
    time_interval=$[$[$[${due_date_s}-${today}]/86400]+1]

    ## we should renew the certification before 30 days
    if [[ ${time_interval} -le 35 ]] && [[ "${host}" != "jenkins" ]] && [[ "${host}" != "dm" ]];then
        echo "[Warning]${url}: remian ${time_interval} days --> Please renew my certification!"

    ##renew test/dev/stage/preprod/prod DN
        case "${domain}" in

                dev)

                    #DN=dev.kaiostech.com
                    export user=iot-user
                    PROXY="${dev_ha[@]}"
                    renew_cert ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                test)

                    #DN=test.kaiostech.com, use kai-user to access to hk test env
                    export user=kai-user
                    PROXY="${test_ha[@]}"
                    #renew_cert ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                stage)

                    #DN=stage.kaiostech.com
                    export user=iot-user
                    PROXY="${stage_ha[@]}"
                    renew_cert ${DN} && \
                    upload_aws_arn ${DN} && \
                    copy_pem_haproxy ${PROXY[@]}  && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                preprod)

                    #DN=preprod.kaiostech.com
                    export user=iot-user
                    PROXY="${preprod_ha[@]}"
                    renew_cert ${DN} && \
                    upload_aws_arn ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                prod)

                    #DN=prod.kaiostech.com
                    export user=iot-user
                    PROXY="${prod_ha[@]}"
                    renew_cert ${DN} && \
                    upload_aws_arn ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                cdn)

                    #DN=cdn.kaiostech.com
                    export user=iot-user
                    renew_cert ${DN} && \
                    upload_aws_arn ${DN} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                api|storage|auth|services|origin)

                    DN=kaiostech.com
                    export user=iot-user
                    PROXY="${kaios_ha[@]}"
                    renew_cert ${DN} && \
                    upload_aws_arn ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                 # For production push
                 push)

                    DN=kaiostech.com
                    export user=iot-user
                    PROXY="${k5_push_ha[@]}"
                    renew_cert ${DN} && \
                    upload_aws_arn ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                 jiosit)

                    #DN=jiosit.kaiostech.com
                    export user=iot-user
                    PROXY="${jiosit_ha[@]}"
                    renew_cert ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                 t001)

                    #DN=t001.kaiostech.com
                    export user=iot-user
                    PROXY="${t001_ha[@]}"
                    renew_cert ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;


                 open)

                    #DN=open.kaiostech.com
                    export user=iot-user
                    PROXY="${open_ha[@]}"
                    renew_cert ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;


                 *)
                    echo "${domain} is not defined in script"; continue
                    ;;

        esac

        ##jenkins and dm.fota proxy are via independent haproxy or ngix, so they are special
        elif [[ ${time_interval} -le 35 ]] && [[ "${host}" == "jenkins" ]];then
            case ${domain} in

                dev)

                    DN=jenkins.dev.kaiostech.com
                    export user=iot-user
                    PROXY="${dev_nginx[@]}"
                    renew_cert ${DN} && \
                    copy_pem_nginx ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                stage) # stage(k4) jenkins is still via haproxy now, will be moved to nginx latter

                    DN=jenkins.stage.kaiostech.com
                    export user=iot-user
                    PROXY="${stage_nginx[@]}"
                    renew_cert ${DN} && \
                    copy_pem_haproxy ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;


                prod)

                    DN=jenkins.prod.kaiostech.com
                    export user=iot-user
                    PROXY="${prod_nginx[@]}"
                    renew_cert ${DN} && \
                    copy_pem_nginx ${PROXY[@]} && \
                    echo "[Succeed] Certification is renewed for ${url}" || {
                    echo "[Failed] Certification renewal failed for ${url}, Aborting"
                    exit
                    }
                    ;;

                 *)
                    echo "${domain} is not defined in script"; exit 2
                    ;;

            esac


        elif [[ ${time_interval} -le 35 ]] && [[ "${host}" == "dm" ]] && [[ "${domain}" == "fota" ]];then

                #DN=fota.kaiostech.com
                export user=iot-user
                PROXY="${fota_ha[@]}"
                renew_cert ${DN} && \
                copy_pem_haproxy ${PROXY[@]} && \
                echo "[Succeed] Certification is renewed for ${url}" || {
                echo "[Failed] Certification renewal failed for ${url}, Aborting"
                exit
                }


    else
        echo  "${url}: still remain ${time_interval}days -> Skip Renew..."

    fi
    sleep 1
done

rm -rf ./domain_list.txt && echo -e "Completed!\n"