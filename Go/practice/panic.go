package main

import (
	"fmt"
	"os"
	"time"
)

type person struct {
	name string
}

func A (per *person){
	per.name="xxx"

}
func SaveTimeNow() {
	tz := "Asia/Shanghai"
	location, _ := time.LoadLocation(tz)
	time_now := time.Now().In(location).Format("2006-01-02 15:04:05")
	savetime := "./time.txt"
	fo, err := os.OpenFile(savetime, os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0666)

	if err != nil {
		fmt.Println("Create savetime file Error", err)
	}

	defer fo.Close()

	_, err2 := fo.Write([]byte(time_now))
	if err != nil {
		fmt.Println("Save time_now Error", err2)
	}

}

func main ()  {
	ins:=person{
		name:"abc",
	}
    fmt.Println("ins is ",ins)
	A(&ins)
	fmt.Println("ins is ",ins)
	SaveTimeNow()
}