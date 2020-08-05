import matplotlib.pyplot as plt
import time
import os

# Get the App_quantity2category map
#read the file

file1="figure1.png"
f=open('category2quantity.map', 'r')

body=f.readlines()

f.close()
source_data = {'mock_verify': 369, 'mock_notify': 192, 'mock_sale': 517}  # 设置原始数据

os.environ['now']=str(now)

#for a, b in body.items():
#    plt.text(a, b + 0.05, '%.0f' % b, ha='center', va='bottom', fontsize=11)  # ha 文字指定在柱体中间， va指定文字位置 fontsize指定文字体大小

# 设置X轴Y轴数据，两者都可以是list或者tuple
category = tuple(source_data.keys())
quantity = tuple(source_data.values())
plt.bar(category, quantity, color='rgb')  # 如果不指定color，所有的柱体都会是一个颜色

plt.xlabel(u"Category")  # 指定x轴描述信息
plt.ylabel(u"Quantity")  # 指定y轴描述信息
plt.title("App-To-Category")  # 指定图表描述信息
plt.ylim(0, 600)  # 指定Y轴的高度
plt.savefig(file1)  # 保存为图片
plt.show()