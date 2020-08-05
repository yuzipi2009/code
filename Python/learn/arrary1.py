
#define an unempty arrary
member=['123',456,'ms',[5,6,7]]
print(member)
#['123', 456, 'ms', [5, 6, 7]]

#define an empty arrary
empty=[]
print(empty)

#append, only append ONE item is OK
#golang: ContentTemp = append(ContentTemp,Content["data"][k])
empty.append(678)
print(empty)
#[678]

#extend, append an arrary is ok
empty.extend([111,222])
print(empty)

#insert (index, item)
empty.insert(0,'firstfirst')
print(empty)
#['firstfirst', 678, 111, 222]