package main

import "fmt"

type notifyOnes struct {
	next_pay_dl int
}

//the play load for notify_paid api when query a imei list
//notifyList := make(map[string]string)


func aaa () {
//var a []map[int]string

a := make([]map[int]notifyOnes, 10)

//a[0] = make(map[int]string, 5)

//a[0][1] = "123"

fmt.Printf ("a0 is %v", a[0])
}

func main (){
	//s :=[]string{}
	//s:=make([]string,1)
	//fmt.Println("arrary s is ",s)
	m :=map[int]string{}
	m2:=make(map[int]string)
	m3:= map[int]string {1:"a"}
	fmt.Println("the length of m3 is ",len(m3))
	//m[10]="aaa"


	//s[0]="abc"
	m[0]="abc"
	m[1]="aaac"
	m[2]="ddddc"
	m2[0]="efg"
	fmt.Printf("map m is %+v\n",m)
	fmt.Println("map m2 is ",m3)
	//fmt.Println(" s is ",s)
	//fmt.Println("map3 m is ",mySlice2)
}