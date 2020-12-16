
#!/usr/bin/python
import paramiko
import os
import re
import csv


port=22
user="svc_do050"
password=r"*Xjx6UsRZn3mRB7?"
delimiter="PLACEHOLDER"


header =["hostname","IPv4","model","cpu_core","memory","mount_point","disk_usage"]
full_data=[]

#mac ips is in the file for loop
mac_list_file=r"./mac_list.txt"

f=open(mac_list_file)

for host in f.readlines():
    print ("++++++++++++++++++++++++++++++")
    #each_mac contains the infor of each mac, so refresh it in each loop
    each_mac=[]

    #increase some weird spaces in the the, just remove it.
    hostname=host.strip()

    each_mac.append(hostname)

    #try ssh connect
    try:
        ssh=paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(hostname,port,user,password,timeout=5)
    except Exception as e:
        print ("ssh connection to %s failed:%s"%(hostname,e))
        each_mac.append("Unaccessable")
        each_mac.append("NA")
        each_mac.append("NA")
        each_mac.append("NA")
        each_mac.append("NA")
        full_data.append(each_mac)
        continue

    _,ips_out,_=ssh.exec_command("ifconfig en0")
    _,model_out,_=ssh.exec_command("sysctl -n hw.model")
    _,vm_out,_=ssh.exec_command("sysctl hw.memsize")
    _,cpu_out,_=ssh.exec_command("sysctl -n hw.ncpu")
    _,partition_out,_=ssh.exec_command("df -g")


    #get ip
    p=re.compile(r'(\d{2}\.\d+\.\d+\.\d+)')
    for line in ips_out.readlines():
        ip_list=p.findall(line)
        if len(ip_list)!=0:
            ip=ip_list[0]
            each_mac.append(ip)

    #get model
    model=model_out.readline()

    #get vm
    mem_byte=vm_out.readline().split(":")[1]
    #print ("mem_byte is ",mem_byte)
    mem_gb="%d%s" % (int(int(mem_byte) / (1024*1024*1024)),"GB")

    #get cpu
    cpu_core=cpu_out.readline()


    each_mac.append(model)
    each_mac.append(cpu_core)
    each_mac.append(mem_gb)

    #get partition
    mount_point_list=[]
    disk_usage_list=[]
    partitions=partition_out.readlines()
    for line_origin in partitions:


        #remove the space at last of the line
        line=line_origin.rstrip()

        line_spilt_space=re.split(r"\s+",line)

        #remove some lines before filter
        if (line_spilt_space[1].isdigit() == False) or (line_spilt_space[1] == "0"):
            continue
        else:
            length=len(line_spilt_space)

            mount_point_normal=line_spilt_space[length-1]
            mount_point_with_space=line_spilt_space[length-2:] #['/Volumes/Macintosh', 'HD']

            if ('/' in mount_point_normal):
                mount_point=mount_point_normal
            else:
                # combine the last 2 item to a new string
                # ['/Volumes/Macintosh', 'HD'] =>/Volumes/Macintosh_HD
                mount_point="_".join(mount_point_with_space)


            disk_usage=line_spilt_space[4]
            mount_point_list.append(mount_point)
            disk_usage_list.append(disk_usage)

        mount_point_html=delimiter.join(mount_point_list)
        disk_usage_html=delimiter.join(disk_usage_list)
    print("mount_point_html is ",mount_point_html)
    print("disk_usage_html is ",disk_usage_html)
    each_mac.append(mount_point_html)
    each_mac.append(disk_usage_html)

    print("FOO %s is %s"%(hostname, mount_point_html))

    full_data.append(each_mac)


f.close()
ssh.close()
print ("finish")

#convert to csv
with open (r'./mac_list.csv','w') as csvfile:
        spawwriter=csv.writer(csvfile,dialect='excel')
        spawwriter.writerow(header)
        for row in full_data:
            spawwriter.writerow(row)

print ("Generate new file")
