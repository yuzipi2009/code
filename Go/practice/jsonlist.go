package main

import (
	"encoding/json"
	"fmt"
)

type example struct {
	Fightid int
	Fightno int
	CompanyId int
}

var arr []string

func main (){
	e:=example{
		Fightid:3,
		Fightno:7,
		CompanyId:3,
	}
	j,_:=json.Marshal(e)
	arr =append(arr,string(j))
	fmt.Printf("aaa:%+v",arr)
}