package main

import (
	"fmt"
	"strconv"
)

type notifyOnex struct {
	Next_pay_dl int `json:"next_pay_dl"`
}

//the play load for notify_paid api when query a imei list

var notifyMap map[string]notifyOnex
var notifyList []map[string]notifyOnex



func main (){
	dataMap:= make (map[string]string)
	dataMap=map[string]string{"192168718812411":"3333333333", "192168718812422":"55555555555"}
	n:=notifyOnex{}
	notifyMap = make(map[string]notifyOnex, 2)
	for k, v := range dataMap{
		fmt.Printf("imei is %s, dl is %s\n", k, v)
		n.Next_pay_dl,_ = strconv.Atoi(v)
		notifyMap[k] = n
		fmt.Printf("map[%s] is %s\n",v,k)
		//notifyList = append(notifyList, notifyMap)
		fmt.Printf("map is %+v\n", notifyMap)
	}
}