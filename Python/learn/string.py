
str='aaa bbb#ccc'

#capitalize: the first str
print(str.capitalize())
#Aaa bbb ccc

print(str.casefold())
print(str.count('a'))
print(str.endswith('c'))
print(str.index('a',1,4))
print(str.find('a'))
print(str.isdigit())
print(str.isupper())

#join()
#the seperator is ${str}, add d infront of each str
print(str.join('ddd'))
#daaa bbb cccdaaa bbb cccd

#strip,lstrip,rstrip
#remove space
print(str.strip())
print(str.split('#'))

