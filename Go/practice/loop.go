package main

import "fmt"

func main(){
	loop("a","b","c","d")

}

func loop (args ... string){

	base:="/a.sh"
	for _,v:=range args{
		fmt.Println("value is ",v)
		base=base + " " + v
		fmt.Println("base is ",base)
	}


}
