#!/usr/bin/python

from email import encoders

from email.header import Header

from email.mime.text import MIMEText

from email.utils import parseaddr, formataddr

import smtplib

import os

import sys


 


#the_file is the target diff file

#the_file=sys.argv[1]


 


# find out the pwd of the diff file

def search_file(path,diff_file):

    items = os.listdir(path)

    for subpath in items:

        pwd = os.path.join(path,subpath)

        if os.path.isdir(pwd):

            search_file(pwd,diff_file)

        elif os.path.isfile(pwd):

            if diff_file in subpath:

                global the_path

                the_path=pwd

                print ("Found file: %s" % the_path)


 


repository = '/Alfresco/Shared/SW_Version/KaiOS2.5_Released_Version_To_ODMs/'


 


# the variable-file, you should set it as a parameter in jenkins

search_file(repository,the_file)


 


# check if the file is really found or not.

try:

    print the_path

except NameError:

    print "Didn't find the file, Aborting.."

    sys.exit(2)


 


#read the file

f=open(the_file,'r')

list=f.readlines()

body=''.join(list).splitlines()

f.close()

    


 


#send email

from_addr = 'xiao.yu@kaiostech.com'

passwd = 'Kaios315'

to_addr = 'xiao.yu@kaiostech.com,ruxin.wang@kaiostech.com'

smtp_addr = 'smtp.office365.com'


 


content = '''Hi All

IMG of %s: %s: 

Below the diff between 33_lite and 31_lite(the last release to customer).

Please kindly let me know once the test is passed, then I can push to customers. \n\n

+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

%s\n\n 

++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Thank you. 

BRs, 

Ruxin,Wang''' %(the_file,the_file,body)


 


def _format_addr(s):

    name, addr = parseaddr(s)

    return formataddr((Header(name).encode(), addr))


 


msg = MIMEText('%s'  % content)

msg['From'] = _format_addr(from_addr)

msg['To'] = _format_addr('%s' % to_addr)

msg['Subject'] = Header('%s internal release for test' % the_file).encode()


 


s = smtplib.SMTP(smtp_addr,587) 

s.starttls()

s.login(from_addr,passwd)

s.sendmail(from_addr,to_addr.split(','),msg.as_string())

s.quit()

 