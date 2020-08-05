package main

import (
	"fmt"
	"reflect"
	"strings"
)

func main()  {
	a:="aaa bbb"
	//b:="xxx,yyy"
	c:=[10]string{}
	fmt.Println(reflect.TypeOf(c))

	a1:=strings.Split(a," ")

	fmt.Println(a1)

}
