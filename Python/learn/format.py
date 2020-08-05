#print ("{0} bb {1}".format("aa","cc"))
#aa bb cc

#print ("%c %c %c" %(97,98,99))
#a b c

a=[1,20,13,-4,52,6,17]
print(sorted(a))
#[-4, 1, 6, 13, 17, 20, 52]

print(reversed(a))
#reversed return a pointer
#<list_reverseiterator object at 0x7f72c12b34e0>
print(list(reversed(a)))
#[17, 6, 52, -4, 13, 20, 1]

print (enumerate(a))
#<enumerate object at 0x7f81ab5ae900>
print (list (enumerate(a)))
#return a list, the item of the list is a list as well
#[(0, 1), (1, 20), (2, 13), (3, -4), (4, 52), (5, 6), (6, 17)]
print (list (enumerate(a))[1][0])
#1

b=['a','b','c','d','e','f']
c=[1,2,3,4]
print (list (zip(b,c)))
#[('a', 1), ('b', 2), ('c', 3), ('d', 4)]