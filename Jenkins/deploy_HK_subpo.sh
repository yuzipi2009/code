#!/usr/bin/env bash
#!/bin/bash


export PATH="/data/tools/repository/node-v10.15.1-linux-x64/bin:$PATH"

source_dir="/data/src/submission_portal"

cd "${source_dir}" && new_version=`awk 'NR==1{print $4}' RELEASE.txt | sed 's/v//'`


cd "${source_dir}" && rm -rf "${source_dir}/node_modules/*"
cd "${source_dir}" && rm -rf "${source_dir}/dist"


cd "${source_dir}" && npm install && npm run fixcrypto \|\| true && ng build --prod --base-href /subpo/

[ $? -ne 0 ] && { echo "build failed";exit;}



cd "${source_dir}/dist" && tar -cvjf "subpo-${new_version}.tar.bz2" *
[ $? -ne 0 ] && { echo "tar failed";exit;}

# generate inventory file

tmp_dir=`mktemp -d`

echo "[nginx]" > ${tmp_dir}/hosts
for node in ${nginx_node}; do echo "${node}" >> ${tmp_dir}/hosts;done


date=`date +%Y%m%d`


cd "/data/ansible-playbooks/submission_portal" && \
ansible-playbook -v --inventory="${tmp_dir}/hosts" --extra-vars "date=${date} new_version=${new_version} source_dir=${source_dir}" deploy_subpo.yml