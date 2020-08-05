package main

import (
	"fmt"
	"strconv"
	"time"
)

func main(){
	ch3:=make (chan string,4)
	go sendData(ch3)

	for {
		v, ok := <-ch3
		if !ok{
			fmt.Println("channel closed!!!")
			break
		}
		fmt.Println("<<<<<read data:",v)
	}
	fmt.Println("main over..")

}
func sendData (ch chan string){
	for i:=0;i<10;i++{
		ch <- "data" + strconv.Itoa(i)

		fmt.Println("send data: ",i)
		time.Sleep(3*time.Second)
	}
	close(ch)
}
