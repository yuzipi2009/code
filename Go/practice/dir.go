package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"
	"strings"
)

func main (){

	/*
	p:="/tmp/test/123"
	fmt.Println("father is",path.Join(p,".."))


	dir, file := path.Split("/tmp/test/123/")

	list2:=[]string{}
	list:=strings.Split(p,"/")
	for _,v:=range list{
		if len(v)!=0{
			list2=append(list2,v)
		}
		//fmt.Printf("i is %d, v is %s\n",i,v)
	}
	fmt.Println("list2 is ",list2)
	p2:=strings.Join(list2[:len(list2)-1],"/")
	fmt.Println("p2 is ",p2)

	return
	/
	 */
	p:="/tmp/test/123"
	pf:=path.Join(p,"..")
	/*
	fmt.Println("a",list[1:len(list)])

	fmt.Println("list is ",list[2])

	fmt.Println("dir is ",dir)
	fmt.Println("file is ",file)
	err:=os.Chdir("/tmp/test")
	fmt.Println("err is ",err)

	 */

	files, err := ioutil.ReadDir("./")
	if err != nil {
		log.Fatal(err)
	}

	for _, f := range files {
		fmt.Println(f.Name())
	}


}
