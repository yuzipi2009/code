package main

import (
	"bytes"
	"fmt"
	"os"
	"strings"
)

func Join() {
    hello := "hello"
    world := "world"

    var a string
    a= strings.Join([]string{hello, world,"aa"}, ",")
    fmt.Println("a is ", a)
}
func writesting() {
	hello := "hello"
	world := "world"

		var buffer bytes.Buffer
		buffer.WriteString(hello)
		buffer.WriteString(",")
		buffer.WriteString(world)
		b := buffer.String()
		fmt.Println("b is ",b)

}
func main()  {

	x:="sfjks/"
	fmt.Println("last",string(x[len(x)-1]))

	filename:="/tmp/test.txt"
	file,_:=os.OpenFile(filename,os.O_RDWR,os.ModePerm)
	defer file.Close()
	bs:=[]byte{5,6}
	fmt.Println("bs is ",bs)
	n,_:=file.Read(bs)
	fmt.Println("n is ",n)
	fmt.Println(string(bs))
	fmt.Println("bs2 is",bs)
	a:=""
	fmt.Println("length is ",len(a))

	arrary:=make([]map[int]string,1)
	for i:=range arrary{
		arrary[i]=make(map[int]string,1)
		arrary[i][10]="OK"
		fmt.Println("map is",arrary[i])
	}
	fmt.Printf("arrary is %T",arrary)
	pname :="Go Flip1 KaiOS 1.0"
	fmt.Println("pname is ",pname)
	pname=strings.Replace(pname," ","_",-1)
	fmt.Println("pname is ",pname)




}