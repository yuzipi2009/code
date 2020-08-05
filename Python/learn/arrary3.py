member=['123',456,'ms',[5,6,7],'123','123','aaa','777','888','999']

print ('123' in member)
#True
print ('123' not in member)
#False

#print all the method of object
print (dir(member))

print (member.count(456))

#find the index of 456
print (member.index(456))

#find '123' from index2 to index5
print (member.index('123',2,5))

#reverse()
#reverse the arrary
member.reverse()
print(member)
#['999', '888', '777', 'aaa', '123', '123', [5, 6, 7], 'ms', 456, '123']

#sort
#golang: d := []int{5, 2, 6, 3, 1, 4} // unsorted
#sort.Sort(sort.IntSlice(d))

member.sort()
member.sort(reverse=True)
print(member)


