package main

import "fmt"

func main () {
	var a []string
	a=make([]string,1)
	a[0]="aaa"
	fmt.Println("a is ",a) //a is  [aaa]
	a[1]="bbb"
	fmt.Println("a is ",a) //panic: runtime error: index out of range
}
