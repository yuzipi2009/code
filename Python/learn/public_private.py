class Person:

    def __init__(self,name):
        self.xxxxxname=name
    __name1='fooooooo'

    def get(self):
        return self.__name1
    name2='456'

p=Person('aaa')
print(p.name2)
#456
print(p.get())
#fooooooo