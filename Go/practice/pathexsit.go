package main

import (
	"fmt"
	"os"
)


func main (){
	path:="/tmp/test.key1"
	out, err := os.Stat(path)
	fmt.Printf("out is %v, err is %v\n",out,err)
	fmt.Println(os.IsNotExist(err))

}
