import pickle

l=[123,'abc',[222,'333']]

f=open('/tmp/foo.txt','w')

try:
    f.writelines(l)
except TypeError as reason:
    print("caught exception,reason is:",reason)
else:
    print ("ok")
finally:
    print("I'm here")


""""
#will save the data as binary, so you can't cat <file> directly
pickle.dump(l,f)
f.close()

f=open('/tmp/foo.txt','rb')
content=pickle.load(f)
print(content)
#[123, 'abc', [222, '333']]
"""