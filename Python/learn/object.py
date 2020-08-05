a=(123,456,789)

b=list(a)
print(type(a))
#<class 'tuple'>
print(type(b))
#<class 'list'>

class list2(list):
    pass

c=list2(a)
c.append('aaa')
print(c)
#[123, 456, 789, 'aaa']