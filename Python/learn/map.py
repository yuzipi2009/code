dict1={1:'123',2:'456',3:'789'}
#{1: '123', 2: '456', 3: '789'}
print (dict1)

#dict(arg), arg is a mapping relationship
dict2=dict([('a',10),('b',20),('c',30)])
print(dict2)
#{'b': 20, 'a': 10, 'c': 30}

for key in dict2.keys():
    print (key)


for value in dict2.values():
    print (value)

for item in dict2.items():
    print (item)
#('b', 20)
#('a', 10)
#('c', 30)

#dic.get(key,message), if key is not found, return message(default is none)
print(dict2.get('c','False'))
#30

print('c' in dict2)
#True

#clear the map
dict1.clear()
print(dict1)
#{}

##same value but not same address
f=dict2
e=dict2.copy()
print(f)
print(e)
print(dict2)
#{'c': 30, 'b': 20, 'a': 10}
#{'c': 30, 'b': 20, 'a': 10}
#{'c': 30, 'b': 20, 'a': 10}

#different mem
print(id(f),id(dict2),id(e))
#140176772448712 140176772448712 140176773232264

dict2['d']='foo'
print(f)
print(e)
print(dict2)
#{'a': 10, 'b': 20, 'd': 'foo', 'c': 30}
#{'a': 10, 'b': 20, 'c': 30}
#{'a': 10, 'b': 20, 'd': 'foo', 'c': 30}

dict2.pop('a')
print(dict2)
#{'d': 'foo', 'c': 30, 'b': 20}

h = {'h':'tooo'}
dict2.update(h)
print(dict2)
#{'b': 20, 'd': 'foo', 'h': 'tooo', 'c': 30}