#!/usr/bin/env bash

# please run this script with root user and add root user public key to iot-user@remote server

now=`date "+%Y-%m-%d %H:%M"`
package_dir="/data/repository/project"

echo "------------rsync from dm-test ${now}--------------"

rsync -av iot-user@54.160.226.113:${package_dir}/* ${package_dir}/ && sudo chown -R root: ${package_dir}
[ $? -eq 0 ] && echo "complete rsync successfully" || {
echo "[Error] rsync failed"
exit
}