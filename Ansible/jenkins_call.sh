#!/usr/bin/env bash

#!/bin/bash

export GOLANG_HOME=/data/tools/repository/go/
export GOROOT=${GOLANG_HOME}
export JAVA_HOME=/data/tools/repository/java

# Maven environment variables
export M2_HOME=/data/tools/repository/apache-maven
export M2=${M2_HOME}/bin
export MAVEN_OPTS="-Xms128m -Xmx256m"
export PATH=${JAVA_HOME}/jre/bin:${JAVA_HOME}/bin:${PATH}:${M2}:${GOLANG_HOME}/bin

call_dir="/data/ansible-playbooks/deployment/empowerthings"
source_dir="/data/src/empowerthings"

# if you select master, you need to define Tags here
#Tags="0.109.15-p23"

#compile binary
cd "${source_dir}" && make clean && make utils && make deploy

[ $? -eq 0 ] || {
echo "complile empowerthings-${Tags} failed"
exit 1
}


# generate ansible vault_pwd file and inventory hosts file
emp_tmp=`mktemp -d`



echo "[FE]" > "${emp_tmp}"/hosts
for node_fe in ${fe};do echo "${node_fe}" >> "${emp_tmp}"/hosts;done

payment=false
echo "[LL]" >> "${emp_tmp}"/hosts
for node_ll in ${ll};do
    echo "${node_ll}" >> "${emp_tmp}"/hosts
    # for payment process on one LL
    if [ $payment == true ];then
    	echo "[Payment_LL]" >> "${emp_tmp}"/hosts
        echo "${node_ll}" >> "${emp_tmp}"/hosts
    fi
    payment=true
done

echo "[DL]" >> "${emp_tmp}"/hosts
for node_dl in ${dl};do echo "${node_dl}" >> "${emp_tmp}"/hosts;done

inventory_file="${emp_tmp}/hosts"

echo "file is :"
cat ${inventory_file}

#gernerate the keys.json with ansible vault
echo "${vault_pw}" > ${emp_tmp}/vault_pwd.txt

vault_file="${emp_tmp}/vault_pwd.txt"
cat ${emp_tmp}/vault_pwd.txt
cp ${emp_tmp}/vault_pwd.txt /tmp/vault_pwd.txt


#Generate keys.json
cd ${call_dir}/files && ansible-vault view keys --vault-password-file "${vault_file}" > keys.json && cat keys.json


##########how to change the content of keys.json###########
#step1: cd ${call_dir}/files
#step2: rm -rf keys
#step3:  ansible-vault create  keys && input the password(${vault_pw})
#step4: input the new keys json
###########################################################


#copy antitheft/cp_vapid key pair to jenkins server
cp -af ${antitheft_vapid_public_pem}  ${call_dir}/files
cp -af ${antitheft_vapid_private_pem} ${call_dir}/files
cp -af ${pc_vapid_public_pem} ${call_dir}/files
cp -af ${pc_vapid_private_pem} ${call_dir}/files

cp -af ${app_push_vapid_private_pem} ${call_dir}/files
cp -af ${app_push_vapid_public_pem} ${call_dir}/files

#echo "check file:"
#cat ${call_dir}/files/${app_push_vapid_public_pem}

cat <<EOF >> "${emp_tmp}"/hosts
[NATA]
172.31.2.224
172.31.14.7
172.31.7.221

[NATB]
172.31.22.43
172.31.30.198
172.31.16.151

EOF

#call deploy_empowerthings.yml
cd "${call_dir}" && ansible-playbook --inventory="${inventory_file}" \
--extra-vars "call_dir=${call_dir} Tags=${Tags}" deploy_empowerthings.yml

#Delete tmp files and keys.json
rm -rf ${call_dir}/files/keys.json
rm -rf ${call_dir}/files/antitheft_vapid*
rm -rf ${call_dir}/files/pc_vapid*
rm -fr ${call_dir}/files/app_push_vapid*
#rm -rf ${source_dir}

now=`date`
echo "============Deployed Empowerthings-${Tags} on stage at ${now}================"

#==================Modify display portal=====================

#Generate POST JWT

date=`date +%Y-%m-%d`

cat > ${emp_tmp}/version.json<<EOF
{
"Date": "${date}",
"Service": "Empowerthings",
"New_Version": "${Tags}",
"Comment": "Null",
"Change": "default"
}
EOF

curl -d @${emp_tmp}/version.json -X POST http://test.kaiostech.com/stage 2>/dev/null


rm -rf ${emp_tmp}
rm -rf ${vault_tmp}