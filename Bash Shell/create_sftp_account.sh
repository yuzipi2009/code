#!/bin/bash

username=$1
role=$2
project_name=$3
base_dir="/data/var/packages"
logdir="/data/bin"

source ./.salt.txt


# Function -help

function print_help () {
    echo "Usage:"
    echo "[cpm_account]: ./create_user.sh CPM_NAME cpm, example: ./create_user.sh zhengyu cpm "
    echo "[pdm_account]: ./create_user.sh ODM_NAME odm PROJECT_NAME, example: ./create_user.sh FISE odm Free "
    exit 0

}


if [ "${role}" == "odm" ];then
    #echo "number is $#"
    if [ $# -ne 3 ];then
        echo "the role project_name should have 3 arguments, aborting..."
        print_help
        exit
    fi

elif  [ "${role}" == "cpm" ];then
    #echo "number is $#"
    if [ $# -ne 2 ];then
        echo "the role cpm should have 2 arguments, aborting..."
        print_help
        exit
    fi
fi


#  Decode the passwd when needed
function decode () {
    echo "${e_passwd}"|openssl aes-128-cbc -d -k ${salt} -base64
}


# Main

today=`date +'%Y-%m-%d %H:%M'`
#only use 8 charaters as the passwd
e_password_full=`echo "${username}"|openssl aes-128-cbc -k ${salt} -base64`
e_password=`echo "$e_password_full"|cut -c 28-`
if [ $? -ne 0 ];then
        echo "encode failed, aborting"
        exit
    fi


if [ $1 = "--help" ] || [ $1 = "-h" ] ;then
    print_help
    exit 0
fi

case ${role} in

    cpm)
    #-M: will not create the login directory
    #-s /sbin/nologin: unable to login to shell
    #-g: the project_name user should belong to sign group
    # ./create_user ${username}(cpm_name) cpm
    useradd -g cpm -s /sbin/nologin -M ${username}
    if [ $? -ne 0 ];then
        echo "creat username failed, aborting"
        exit
    fi


    #set password for username
    echo ${e_password} | passwd ${username} --stdin
    if [ $? -ne 0 ];then
        echo "set password for ${username} failed, aborting"
        exit
    fi

    echo "Created ${username} and set password successfully"

    cat >> ${logdir}/.history.txt <<EOF
==========${today}==========
username: "$username"
password: "$e_password"
full_password: "$e_password_full"
===================================

EOF
    ;;

    odm)
    # $username is odm_name
    #./create_user ${username}(odm_name) odm ${project_name}
    useradd -g sign -s /sbin/nologin -M ${username}
    #create user for odm is different, because one odm may have multiple projects, so we can't exit if the user is alredy exsit.
    if [ $? -ne 0 ];then
        echo "[Warning] odm ${username} is alreday exsit, just create directories for the project"
    else
        #set password
        echo ${e_password} | passwd ${username} --stdin
        if [ $? -ne 0 ];then
            echo "[Error] set password for ${username} failed, aborting"
            exit
        fi
        echo "(1/3) Created ${username} for ${project_name}-${username} and set password successfully"
    fi

    #check if the directory is already exsit
    if [ -d ${base_dir}/${username}/${project_name} ];then
        echo "[Error] directory is also exsit, please check again, Aborting."
    else
        #create directories
        mkdir -p ${base_dir}/${username}/${project_name}/{SWbuild_Candidate,SWbuild_Input,SWbuild_Release} || { echo "create directories failed";exit;}
        echo "(2/3) Created diretories successfully"

        #set owner of directories
        cd ${base_dir} && chmod -R 555 ${username}  && cd ${username}/${project_name} && chmod  777 SWbuild_Input && \
        chmod 707 SWbuild_Candidate && chmod 557 SWbuild_Release && cd ${base_dir}  && chown -R root:sign ${username} && echo "(3/3) Set diretories permission successfully"|| { echo "set permission failed";exit;}

        # wrire_log
        cat >> ${logdir}/.history.txt <<EOF
==========${today}==========
username: $username
project_name: $project_name
password: $e_password
full_password: "$e_password_full"
===================================

EOF

fi
    ;;

    *)
    echo "You should use odm or cpm as the 2nd parameter."
    ;;


esac