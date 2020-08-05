package main

import (
	"fmt"
	"time"
)

func main(){
	now:=time.Now().Format("20060102150405")
	//a:=now.Format("150405")
	fmt.Println(now)
}
