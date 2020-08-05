member=['123',456,'ms',[5,6,7]]

#remove item from arrary
member.remove('123')
print(member)
#[456, 'ms', [5, 6, 7]]

#del
# note: it is not an array method
del member[1]
# delete the arrary
del member
print(member)
#NameError: name 'member' is not define

#pop()
#get the last item in an arrary AND remove it from the arrary
item=member.pop()
print(item) #[5, 6, 7]
print(member) #[456, 'ms']


