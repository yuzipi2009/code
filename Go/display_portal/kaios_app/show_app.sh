#!/bin/bash

today=`date "+%Y-%m-%d_%H:%M"`

echo "==========${today}========="

sh ./gen_ajax_1.2.sh && \
python3 gen_figure.py && echo "2 figures are generated" || echo "Generate figures failed."

#scp figures to django server

figure_dir="/data/tools/repository/nginx/html/app/static/kaios_app"
table="/data/tools/repository/nginx/html/app/table.html"
ssh kai-user@10.81.74.17 "sudo su -c 'rm -rf /home/kai-user/figure*.png'"
scp figure1.png figure2.png kai-user@10.81.74.17:./
ssh kai-user@10.81.74.17 "sudo su -c ' mv /home/kai-user/figure*.png ${figure_dir}'"
[ $? -eq 0 ] && echo "Copied figures to target directory" || echo "Copy figures failed"
