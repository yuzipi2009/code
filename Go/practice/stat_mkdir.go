package main

import (
	"fmt"
	"os"
)

func main ()  {
	info,err:=os.Stat("/tmp/test/ok")
	fmt.Println("info is ",info)
	fmt.Println("err is ",err)

	err=os.MkdirAll("/tmp/test/ok/ok",os.ModePerm)
	fmt.Println("err is ",err)

}
