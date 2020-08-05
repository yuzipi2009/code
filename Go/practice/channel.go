package main

import (
	"fmt"
)

func main (){
	var c1 chan string
	c1=make (chan string)
	<-c1 //从c1读取数据，但是忽略接收方，仍然阻塞了，等待另一个goroutine往c1里写数据。
	c1 <- "456" //第10行已经被阻塞了，所以这里永远不会被执行，deadlock.
	fmt.Println("Read from channel")
}
