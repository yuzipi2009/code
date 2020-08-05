set1={1,2,3,4,5}
print(type(set1))
print(set1)
#{1, 2, 3, 4, 5}
#set function, you pass a list tuple

set2=set([5,6,67,8,8])
print(set2)
#{8, 67, 5, 6}

#how to uniq the items in a list/tuple/set
#method1:use list

list1=['a','b','b','c','c','c','d']
temp=[]
for i in list1:
    if i not in temp:
        temp.append(i)
print(temp)
#['a', 'b', 'c', 'd']

#method2: use set
#set(list) will uniq the list
#but set will change the order, be careful
print(list(set(list1)))
#['a', 'b', 'd', 'c']

set3=frozenset([1,2,3,4])
set3.add(5)