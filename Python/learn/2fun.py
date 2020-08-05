def fun1():
    print ("fun1")
    x=5
    def fun2():
        nonlocal x
        x *= x
        print('x is ',x)
    return fun2

fun1()()



