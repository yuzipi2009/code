import matplotlib.pyplot as plt
import matplotlib.axes as ax
import time
import os
import json

# Get the App_quantity2category map
# read the file

plt.figure()
file1="figure1.png"
f=open('category2quantity.map', 'r')
body=f.readline()
#for line in f.readline():
#    print (line)
#print (f.readlines())
f.close()

source=json.loads(body)
height=source['Games']+10


#os.environ['now']=str(now)

for a, b in source.items():
    plt.text(a, b + 0.05, '%.0f' % b, ha='center', va='bottom', fontsize=11)  


category = source.keys()
quantity = source.values()

#print (category,quantity)
plt.bar(category, quantity, color='bgrcmyk') 

plt.xticks(rotation=15)
plt.xlabel(u"Category") 
plt.ylabel(u"Quantity")  
plt.title("Category-To-Quantity",fontsize=20)  
plt.ylim(0,height) 
plt.savefig(file1) 


##############Fingure_2#################
plt.figure()
file2="figure2.png"

#color=[b,g,r,c,m,y,k]

# set the fingure size
fig = plt.figure(figsize=(8,8))

# set x raxi and y rax
plt.axes(aspect=1)

#ax1 = fig.add_subplot(111)
plt.title('Category-To-Percentage', fontsize=20)

categorys = list(source.keys())
quantitys = list(source.values())

#category=x[0] for x in source.
labels = ['{}:{}'.format(key,value) for key, value in zip(categorys,quantitys)]
fracs = list(source.values())
#print ("key is ",labels)
#print ("value is", fracs)

# set offset
explode = [x * 0 for x in range(len(source))]

#print (range(len(source)))

plt.pie(fracs, labels = labels, explode=explode, autopct='%3.1f %%', shadow=True, labeldistance=1.05, startangle=0, pctdistance=0.8, center=(0, 0)
)
plt.legend(loc=7, bbox_to_anchor=(1.1, 0.80), ncol=2, fancybox=True, shadow=True, fontsize=11)

plt.savefig(file2)
