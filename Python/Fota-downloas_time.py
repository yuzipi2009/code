#  Author: Yu Xiao
#  Mail: xiao.yu@kaiostech.com
#  Date: 2018/08

#  Author: Yu Xiao
#  Mail: xiao.yu@kaiostech.com
#  Date: 2018/08


import pymysql
import pandas as pd
import matplotlib.pyplot as plt
# noinspection PyInterpreter
import matplotlib.ticker as ticker
import urllib.request
import json
import numpy as np
import time
import win32com.client as win32
import xlrd


# create connect
conn = pymysql.connect(host='localhost', port=3306, user='root', password='yuxiao123', database='fota_report')

# create cursor
#cursor = conn.cursor()


# select the user_imei and the time_diff which means doownload time
result1 = pd.read_sql('select imei_1,stat_ip,time_1,stat_to_version, TIMESTAMPDIFF( SECOND, time_1, time_2 ) AS download_time '
                      'from '
                      '( (SELECT stat_imei as imei_1, stat_ip, stat_to_version,stat_datetime as time_1 '
                      'FROM data1 d1 '
                      'WHERE d1.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) '
                      'FROM '
                      'data1 '
                      'WHERE stat_operation = 100 AND d1.stat_imei = stat_imei ))t1 '
                      'INNER JOIN ( SELECT stat_imei as imei_2, stat_datetime as time_2 '
                      'FROM '
                      'data1 d2 '
                      'WHERE d2.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) FROM data1 '
                      'WHERE stat_operation = 1000 AND d2.stat_imei = stat_imei ))t2 on imei_1 = imei_2)'
                      'where time_2 > time_1 ORDER BY download_time', con=conn)

imei = list(result1.imei_1)
DLtime = list(result1.download_time)
date = list(result1.time_1)[0].split( )[0]
time_range1 = list(result1.time_1)
version = list(result1.stat_to_version)[0]
count = len(imei)
ipaddr = list(result1.stat_ip)
country = []

# slect imei, ip where time_diff>x
result2 = pd.read_sql('select imei_1,stat_ip,TIMESTAMPDIFF( SECOND, time_1, time_2 ) AS download_time '
                      'from '
                      '( (SELECT stat_imei as imei_1, stat_ip,stat_datetime as time_1 '
                      'FROM data1 d1 '
                      'WHERE d1.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) '
                      'FROM '
                      'data1 '
                      'WHERE stat_operation = 100 AND d1.stat_imei = stat_imei ))t1 '
                      'INNER JOIN ( SELECT stat_imei as imei_2, stat_datetime as time_2 '
                      'FROM '
                      'data1 d2 '
                      'WHERE d2.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) FROM data1 '
                      'WHERE stat_operation = 1000 AND d2.stat_imei = stat_imei ))t2 on imei_1 = imei_2) '
                      'where TIMESTAMPDIFF( SECOND, time_1, time_2 ) > 1800 and time_2 > time_1 order by download_time ', con=conn)




time_range2=[]
imei2 = list(result2.imei_1)
DLtime2 = list(result2.download_time)
ipaddr2 = list(result2.stat_ip)
country1=[]
count2=len(imei2)
country_count=[]


# slect imei, ip where time_diff < 60
result3 = pd.read_sql('select imei_1,TIMESTAMPDIFF( SECOND, time_1, time_2 ) AS download_time '
                      'from '
                      '( (SELECT stat_imei as imei_1, stat_ip,stat_datetime as time_1 '
                      'FROM data1 d1 '
                      'WHERE d1.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) '
                      'FROM '
                      'data1 '
                      'WHERE stat_operation = 100 AND d1.stat_imei = stat_imei ))t1 '
                      'INNER JOIN ( SELECT stat_imei as imei_2, stat_datetime as time_2 '
                      'FROM '
                      'data1 d2 '
                      'WHERE d2.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) FROM data1 '
                      'WHERE stat_operation = 1000 AND d2.stat_imei = stat_imei ))t2 on imei_1 = imei_2) '
                      'where TIMESTAMPDIFF( SECOND, time_1, time_2 ) <= 300 and  time_2 > time_1', con=conn)

imei3=list(result3.imei_1)
count3=len(imei3)

# slect imei, ip where 61< time_diff < 300
result4 = pd.read_sql('select imei_1,TIMESTAMPDIFF( SECOND, time_1, time_2 ) AS download_time '
                      'from '
                      '( (SELECT stat_imei as imei_1, stat_ip,stat_datetime as time_1 '
                      'FROM data1 d1 '
                      'WHERE d1.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) '
                      'FROM '
                      'data1 '
                      'WHERE stat_operation = 100 AND d1.stat_imei = stat_imei ))t1 '
                      'INNER JOIN ( SELECT stat_imei as imei_2, stat_datetime as time_2 '
                      'FROM '
                      'data1 d2 '
                      'WHERE d2.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) FROM data1 '
                      'WHERE stat_operation = 1000 AND d2.stat_imei = stat_imei ))t2 on imei_1 = imei_2) '
                      'where TIMESTAMPDIFF( SECOND, time_1, time_2 ) < 600 and  TIMESTAMPDIFF( SECOND, time_1, time_2 ) > 300 '
                      'and time_2 > time_1'
                      , con=conn)

imei4=list(result4.imei_1)
count4=len(imei4)


# slect imei, ip where 300< time_diff < 600
result5 = pd.read_sql('select imei_1,TIMESTAMPDIFF( SECOND, time_1, time_2 ) AS download_time '
                      'from '
                      '( (SELECT stat_imei as imei_1, stat_ip,stat_datetime as time_1 '
                      'FROM data1 d1 '
                      'WHERE d1.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) '
                      'FROM '
                      'data1 '
                      'WHERE stat_operation = 100 AND d1.stat_imei = stat_imei ))t1 '
                      'INNER JOIN ( SELECT stat_imei as imei_2, stat_datetime as time_2 '
                      'FROM '
                      'data1 d2 '
                      'WHERE d2.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) FROM data1 '
                      'WHERE stat_operation = 1000 AND d2.stat_imei = stat_imei ))t2 on imei_1 = imei_2) '
                      'where TIMESTAMPDIFF( SECOND, time_1, time_2 ) < 1200 and  TIMESTAMPDIFF( SECOND, time_1, time_2 ) >= 600 '
                      'and time_2 > time_1'
                      , con=conn)

imei5=list(result5.imei_1)
count5=len(imei5)

# slect imei, ip where 61< time_diff > 600
result5 = pd.read_sql('select imei_1,TIMESTAMPDIFF( SECOND, time_1, time_2 ) AS download_time '
                      'from '
                      '( (SELECT stat_imei as imei_1, stat_ip,stat_datetime as time_1 '
                      'FROM data1 d1 '
                      'WHERE d1.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) '
                      'FROM '
                      'data1 '
                      'WHERE stat_operation = 100 AND d1.stat_imei = stat_imei ))t1 '
                      'INNER JOIN ( SELECT stat_imei as imei_2, stat_datetime as time_2 '
                      'FROM '
                      'data1 d2 '
                      'WHERE d2.stat_status = 999 and stat_datetime = ( SELECT max( stat_datetime ) FROM data1 '
                      'WHERE stat_operation = 1000 AND d2.stat_imei = stat_imei ))t2 on imei_1 = imei_2) '
                      'where TIMESTAMPDIFF( SECOND, time_1, time_2 ) >= 1200 and time_2 > time_1 '
                      , con=conn)


imei6=list(result5.imei_1)
count6=len(imei6)

#define the percentage of the number of phones  on the condition of download time, and change from 0.1 to 10%

percentage1 = '%.2f%%' %(count3*100/count)
percentage2 = '%.2f%%' % (count4*100/count)
percentage3 = '%.2f%%' %(count5*100/count)
percentage4 = '%.2f%%' %(count6*100/count)






#this function is to transform ip to city, with the url can generate much information, then filter the city info and
#insert into country[] one by one .

def ip_country(i):
    url = 'http://api.ipstack.com/%s?access_key=89585f3e6d6e9d052d946d0885b036d4' % (i)
    urlobject = urllib.request.urlopen(url)
    urlcontent = urlobject.read()
    res = json.loads(urlcontent)
    item = res['country_name']
    append = country.append
    append(item)


# generate the county_name list from ip on the condition of time_diff > 5000
for i in ipaddr2:
    ip_country(i)



#for thoes phones whose download time > 8000, they have repeated cities, this circle is used to generate the unique
#value for these cities
for item in country:
    if item not in country1:
        country1.append(item)

# above circle is to generate unique city name list, the below circle is to count the numbers of these cities,
# and the city name <-> number of city are one by one sequential.
for item2 in country1:
    country_count.append(country.count(item2))


#define the time format, and the location where we save the 2 fingures
local_time = time.strftime('%Y-%m-%d',time.localtime())
file1="C:\/fota_report\%s_overview.png" %local_time
file2="C:\/fota_report\%s_filter_countries.png" %local_time

#conn.close()

####################################start to draw figures##################################################

#draw the first figure
plt.figure()             #if you want to draw 2 fingures, you need to use this sentence for each figure.
#plt.subplot(212)     # this is used to draw multifigures in one picture
figsize = 10,3
font2 = {'family' : 'Times New Roman', 'weight' : 'normal','size' : 16,}
plt.rc('figure',autolayout = True)
plt.plot(imei,DLtime,'.')       #this sentence is to generate figures, x-axis is imei and y-axis is DLtime
plt.xticks([])                # this sentence is to fully use all space, self-adjusting.

plt.axhline(y=300,color='r') # draw a standerd  line as a bechmark
plt.ylabel("time_consumed (seconds)",font2)
plt.title("%s phones download version '%s' on %s"%(count,version,date),font2)
#plt.grid(True)        #draw the grid

############################draw the firstlegend#############################################33
p1, = plt.plot([1,2,3],'r-',label='300 seconds as bechmark')  #draw a lengend
p2, = plt.plot([3,2,1],'b.',label='download_time')
first_lengend = plt.legend(handles=[p1,p2],loc=2)

ax = plt.gca().add_artist(first_lengend)   #if we don't add this row, the two lengend can't be divided

############################draw another legend#####################################
p3, =plt.plot([4,5,6], 'k.', label='  5min> %s  ' %percentage1)
p4, =plt.plot([4,5,6],'k.', label=' 5min < %s < 10min' %percentage2)
p5, =plt.plot([4,5,6], 'k.',label=' 10min < %s < 20min' %percentage3)
p6, =plt.plot([4,5,6],'k.', label=' 20min < %s ' %percentage4)
plt.legend(handles=[p3,p4,p5,p6],loc='center left')   #this is used to modify legent fontsize
leg = plt.gca().get_legend()
ltext = leg.get_texts()
plt.setp(ltext, fontsize='xx-large')
plt.savefig(file1)


# draw second fingure
plt.figure()
#plt.subplot(211)
figsize = 9,15
font2 = {'family' : 'Times New Roman', 'weight' : 'normal','size' : 16,}
plt.rc('figure',autolayout = True)
plt.title("%s phones fronm below countries spend > 30 minutes to download"%count2 )
plt.xlabel("Number of phones",font2)
plt.barh(range(len(country_count)), country_count, tick_label=country1)
#plt.grid(True)
#plt.xticks([])
plt.savefig(file2)
plt.show()


##############/################below is the function to send email

outlook = win32.gencache.EnsureDispatch('outlook.application')
mail = outlook.CreateItem(0)
receivers = ['xiao.yu@kaiostech.com','qingzhong.guo@kaiostech.com','jun.yin@kaiostech.com','weiqing.song@kaiostech.com',
             'raffi.semerciyan@kaiostech.com','saber.nabil@kaiostech.com','huijuan.jiao@kaiostech.com']

mail.Recipients.Add(receivers[0]) #me
#mail.Recipients.Add(receivers[1]) #Guo
#mail.Recipients.Add(receivers[2]) #Yin jun
#mail.Recipients.Add(receivers[3]) #Tim
#mail.Recipients.Add(receivers[4]) #Raffi
#mail.Recipients.Add(receivers[5]) #Saber
#mail.Recipients.Add(receivers[6]) #jiao hui juan

#mail.To = receivers[2]
mail.Subject = 'FOTA report of %s' %(date)


content = str('send from python3.6, win32.client.')

mail.Body = content
mail.Attachments.Add(file1)
mail.Attachments.Add(file2)
mail.Send()


'''
#third fingure, this is another type of bar-graph, use in the future 
plt.subplot(212)
figsize = 11,9
font2 = {'family' : 'Times New Roman', 'weight' : 'normal','size' : 16,}
plt.rc('figure',autolayout = True)
plt.xticks([])
plt.bar(range(len(time_range2)), time_range2,color='rgb',tick_label=imei)
plt.show()
'''



