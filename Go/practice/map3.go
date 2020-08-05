package main

import "fmt"

var m=make(map[string]map[string]string)



func main ()  {
	m["123123123123"]=make(map[string]string)
	m["123123123123"]["msg"]="Congratulation"
	m["curef"]=make(map[string]string)
	m["curef"]["msg"]="QRD8905-TFOTA"
	delete(m,"curef")
	//m=[{"123123123123":{"msg":"Congratulation"},"curef":{"msg":"QRD8905-TFOTA"}}]
	fmt.Println("m is ",m)

}