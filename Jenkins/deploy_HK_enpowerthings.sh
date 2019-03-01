#!/bin/bash

call_dir="/data/ansible-playbooks/empowerthings"

# Note: Don't forget to change below 2 variables in groub_vars if you change the emp and jdk version.
# jdk="jdk-1.8.0.144"
# version="empowerthings-0.99.54-p9"


# generate ansible vault_pwd and inventory hosts file
emp_tmp=`mktemp -d`

echo "[FE]" > "${emp_tmp}"/hosts
for node_fe in "${fe}";do echo "${node_fe}" >> "${emp_tmp}"/hosts;done

echo "[LL]" >> "${emp_tmp}"/hosts
for node_ll in "${ll}";do echo "${node_ll}" >> "${emp_tmp}"/hosts;done

echo "[DL]" >> "${emp_tmp}"/hosts
for node_dl in "${dl}";do echo "${node_dl}" >> "${emp_tmp}"/hosts;done

inventory_file="${emp_tmp}/hosts"

echo "${vault_pw}" > ${emp_tmp}/vault_pwd.txt

vault_file="${emp_tmp}/vault_pwd.txt"

#Generate keys,json
cd ${call_dir}/files && ansible-vault view keys --vault-password-file "${vault_file}" > keys.json


#call deploy_empowerthings.yml
cd "${call_dir}" && ansible-playbook --inventory="${inventory_file}" \
--extra-vars "vault_file=${vault_file} call_dir=${call_dir}" deploy_empowerthings.yml

#Delete tmp files and keys.json
rm -rf /tmp/tmp.* && \
rm -rf ${call_dir}/files/keys.json