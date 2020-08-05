g=lambda x,y:x+y

print(g(5,6))
#11

def odd(x):
    return x%2==0

l=range(10)

print (list(filter(odd,l)))
#[0, 2, 4, 6, 8]

#True=1，False=0 in python
print (list(filter(lambda x:x%2,l)))
#[1, 3, 5, 7, 9]

print (list(map(lambda x:x*2,l)))
#[0, 2, 4, 6, 8, 10, 12, 14, 16, 18]