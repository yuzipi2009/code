#!/usr/bin/env bash
env_alias="k4"
region_alias="na2"
region="us-east-1"
ami_id="ami-070302c3a13f53542"
version=""
port=""
redis_version="3.0.7"
cql_file=`mktemp -d`"/additions.cql"
sa_scripts_version="2.0"
emp_ver_num="3"

# HAPROXY Domain Name Mappings
ha_developer_url="developer.preprod.kaiostech.com"
hostname1="k4-na2-ha-a-001"
hostname2="k4-na2-ha-c-001"
ip1="192.168.48.148"
ip2="192.168.66.119"


if [[ -n ${additions} ]]; then

    echo "${additions}" > "${cql_file}"
    cd /data/ansible-playbooks/vpc && ansible-playbook -v \
        --extra-vars "cql_script_src_file=${cql_file}" cqlsh.yml
fi

for node_type in ${node_type_list[@]}; do

    if [ "${node_type}" == "fe" ]; then
    	version="${emp_version}"
        port="8080"
    elif [ "${node_type}" == "dl" ] || [ "${node_type}" == "ll" ]; then
    	version="${emp_version}"
    elif [ "${node_type}" == "sa" ]; then

    	if [ -z "${emp_version}" ]; then
    		echo "emp_version is required for node_type ${node_type} to match nats subject names"
    		exit 1
    	fi

    	version="${sa_version}:${emp_version}"
    elif [ "${node_type}" == "devl" ]; then
    	version="${devl_version}"
        port="8081"
    elif [ "${node_type}" == "subp" ]; then
    	version="${subp_version}"
        port="8082"
    elif [ "${node_type}" == "anti" ]; then
    	version="${anti_version}"
        port="8083"
    elif [ "${node_type}" == "atapi" ]; then
    	version="${anti_version}"
        port="8087"
    elif [ "${node_type}" == "atui" ]; then
    	version="${anti_version}"
        port="8085"
    fi

    if [ -z "${version}" ]; then
    	echo "version is missing for node_type ${node_type}"
    	exit 1
    fi

    for subnet_alias in ${subnet_alias_list[@]}; do


  		echo "================================== Launching ${node_type} ${subnet_alias} ========================="

    	if [ "${node_type}" == "fe" ] || [ "${node_type}" == "ll" ]; then
      		public_ip="yes"
    	else
      		public_ip="no"
    	fi

		hostname="${env_alias}-${region_alias}-${node_type}-${subnet_alias}-${instance_index}"

    	cd /data/ansible-playbooks/vpc && ansible-playbook -vvv \
        	--extra-vars "env_alias=${env_alias} node_type=${node_type} port=${port} region=${region} \
        	region_alias=${region_alias} subnet_alias=${subnet_alias} instance_index=${instance_index} \
        	ami_id=${ami_id} instance_type=${instance_type} version=${version}  \
        	public_ip=${public_ip} \
        	ec2_access_key=${ec2_access_key} ec2_secret_key=${ec2_secret_key}" launch.yml

        job_tmp=`mktemp -d`
        node_data_file="${job_tmp}/node_data.txt"
        touch "${node_data_file}"
    	redis_json_file="${job_tmp}/rema_list.json"
    	first_redis_json_file="${job_tmp}/rema_first.json"

        echo "Sleeping 10 secs while new host gets sshd up and running"
        sleep 15

        # Determine system facts
        cd /data/ansible-playbooks/vpc && ansible-playbook -vvv \
            --extra-vars "redis_json_file=${redis_json_file} first_redis_json_file=${first_redis_json_file} \
            node_data_file=${node_data_file} env=${env_alias} hostname=${hostname} ec2_region=${region} \
            ec2_access_key=${ec2_access_key} ec2_secret_key=${ec2_secret_key}" system_facts.yml

        if [ -s "${redis_json_file}" ]; then
            /data/ansible-playbooks/vpc/bash/AwsToRedisCluster.py \
                "redis_cluster" "${redis_json_file}" >> "${node_data_file}"
        fi

        # Re-source node data to get additional facts from system_facts ansible script
        source "${node_data_file}"

        # Create Ansible Hosts File
        inv_file="$job_tmp/inv.yaml"
        echo "---" > "${inv_file}"
        echo "${env_alias}:" >> "${inv_file}"
        echo "  hosts:" >> "${inv_file}"
        echo "    ${hostname}:" >> "${inv_file}"
        echo "      ansible_host: ${ip}" >> "${inv_file}"


		if [ "${node_type}" == "fe" ] || [ "${node_type}" == "ll" ] || [ "${node_type}" == "dl" ]; then

          # Install Empowerthings
          source_dir="/data/src/empowerthings/${version}/"
          emp_tmp_dir="/data/src/empowerthings/tmp/"

          cd "${emp_tmp_dir}" && echo "${vault_pw}" > "${emp_tmp_dir}pw.txt"
          cd "${emp_tmp_dir}" && ansible-vault view --vault-password-file="${emp_tmp_dir}pw.txt" "/data/var/ansible/k4key.json" > keys.json

		  if [ "${node_type}" == "fe" ] || [ "${node_type}" == "dl" ]; then
           	  source_conf="conf/cumulis3.conf"
              dest_conf="conf/cumulis3.conf"
              run_node="${node_type}3"

          elif [ "${node_type}" == "ll" ]; then
           	  source_conf="conf/cumulis3.conf"
              dest_conf="conf/cumulis3.conf"
              run_node="ll3"

              cd "${emp_tmp_dir}" && ansible-vault view --vault-password-file="${emp_tmp_dir}pw.txt" "/data/var/ansible/antitheft_vapid_private.pem" > antitheft_vapid_private.pem
              cd "${emp_tmp_dir}" && ansible-vault view --vault-password-file="${emp_tmp_dir}pw.txt" "/data/var/ansible/antitheft_vapid_public.pem" > antitheft_vapid_public.pem
          fi

          cd /data/ansible-playbooks/vpc && ansible-playbook -v --inventory="${inv_file}" \
                --extra-vars "new_version=${version} source_dir=${source_dir} env=${env_alias} tmp_dir=${emp_tmp_dir} \
                ip=${ip} hostname=${hostname} \
                source_conf=${source_conf} dest_conf=${dest_conf} run_node=${run_node} emp_ver_num=${emp_ver_num}" empowerthings.yml

          rm -f "${emp_tmp_dir}/*"

          if [ "${node_type}" == "fe" ]; then
              ha_family="middleware"
              ha_port="8080"
          fi

    	elif [ "${node_type}" == "sa" ]; then

		  # Break the empowerthings version off of sa version
          IFS=: read sa_version emp_version <<< "${version}"

          # Install Signapp
          source_dir="/data/src/signapp/${sa_version}/"
          emp_tmp_dir="/data/src/signapp/tmp/"

          cd "${emp_tmp_dir}" && echo "${vault_pw}" > "${emp_tmp_dir}pw.txt"
          cd "${emp_tmp_dir}" && ansible-vault view --vault-password-file="${emp_tmp_dir}pw.txt" "/data/var/ansible/k4key.json" > keys.json

          cd /data/ansible-playbooks/vpc && ansible-playbook -v --inventory="${inv_file}" \
            --extra-vars "new_version=${sa_version} emp_version=${emp_version} source_dir=${source_dir} env=${env_alias} tmp_dir=${emp_tmp_dir} \
            ip=${ip} hostname=${hostname} scripts_version=${sa_scripts_version}" signapp.yml

        elif [ "${node_type}" == "devl" ]; then

            # Install Dev Login
            ha_family="tomcat"
            ha_port="8081"
            source_dir="/data/src/dev_login/${version}/"
            cd /data/ansible-playbooks/vpc && ansible-playbook -v \
                --inventory="${inv_file}" \
                --extra-vars "new_version=${version} source_dir=${source_dir} \
                redis_cluster=${redis_cluster} instance_id=${instance_id} \
                env=${env_alias} ip=${ip} hostname=${hostname} \
                ha_hostname=${ha_developer_url} ha_ip=${ip1}" devlogin.yml

        elif [ "${node_type}" == "anti" ]; then

            # Install Dev Login
            ha_family="tomcat"
            ha_port="8085"
            source_dir="/data/src/antitheft/${version}/"
            cd /data/ansible-playbooks/vpc && ansible-playbook -v \
                --inventory="${inv_file}" \
                --extra-vars "new_version=${version} source_dir=${source_dir} \
                redis_cluster=${redis_cluster} instance_id=${instance_id} \
                env=${env_alias} ip=${ip} hostname=${hostname}" antitheft.yml

        elif [ "${node_type}" == "subp" ]; then

            # Install Submission Portal
            ha_family="misc"
            ha_port="8082"
            source_dir="/data/src/submission_portal/${version}/"
            cd /data/ansible-playbooks/vpc && ansible-playbook -v --inventory="${inv_file}" \
                --extra-vars "new_version=${version} source_dir=${source_dir} \
                env=${env_alias} ip=${ip} hostname=${hostname}" subpo.yml


        elif [ "${node_type}" == "atui" ]; then

            # Install Service Center
            ha_family="misc"
            ha_port="8085"
            source_dir="/data/src/antitheft-optimized-ui/${version}/"
            cd /data/ansible-playbooks/vpc && ansible-playbook -v --inventory="${inv_file}" \
                --extra-vars "new_version=${version} source_dir=${source_dir} \
                env=${env_alias} ip=${ip} hostname=${hostname}" atui.yml

        fi


        if [ "${node_type}" != "dl" ] && [ "${node_type}" != "ll" ] && [ "${node_type}" != "sa" ]; then

          node_ips_filename="$job_tmp/node_ips"
          touch "${node_ips_filename}"
          cd /data/ansible-playbooks/vpc && ansible-playbook -v \
              --extra-vars "ha_port=${ha_port} node_type=${node_type} region=${region} hostname=${hostname} \
               env_alias=${env_alias} subnet_alias=${subnet_alias} node_ips_filename=${node_ips_filename} \
                ec2_access_key=${ec2_access_key} ec2_secret_key=${ec2_secret_key}" node_type_facts.yml


          # Create Ansible Hosts File
          inv_file="$job_tmp/ha_inv.yaml"
          echo "---" > "${inv_file}"
          echo "${env_alias}:" >> "${inv_file}"
          echo "  hosts:" >> "${inv_file}"
          echo "    ${hostname1}:" >> "${inv_file}"
          echo "      ansible_host: ${ip1}" >> "${inv_file}"
          echo "    ${hostname2}:" >> "${inv_file}"
          echo "      ansible_host: ${ip2}" >> "${inv_file}"

          cd /data/ansible-playbooks/vpc/haproxy && ansible-playbook -v --inventory="${inv_file}" \
              --extra-vars "ha_port=${ha_port} node_type=${node_type} \
               env=${env_alias} node_ips_filename=${node_ips_filename}" haproxy_config_update.yml

        fi
    done