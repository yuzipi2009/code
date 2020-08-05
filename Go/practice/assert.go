package main

import (
	"encoding/json"
	"fmt"
	"github.com/pkg/errors"
)

func EditResponse (c int,m interface{}){
	type playload struct {
		Code int `json:"code"`
		Response string `json:"response"`
	}

	var p playload
	p.Code = c
    //a:=error.Error(m)
    //fmt.Println("a is ",a)
	switch m.(type) {
	case error:
		p.Response = m.Error
	//case error:


		resp, _ := json.Marshal(p)
		fmt.Println(p)
		fmt.Println(string(resp))

}

func main()  {
	m:=errors.New("fail").Error()
	//m.Error()
	//n:=error.Error(m)

	//fmt.Printf("m is %v",m)
	//	//m:="ok"
	EditResponse(401,m)

}