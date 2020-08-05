package main

import (
	"encoding/json"
	"fmt"
	"reflect"
)

type Foo struct {
	Name string `json:"name"`
	Age int
	Sex string
	Aaa int `json:"AAA"`
	Bbb string

}

func main()  {
	me := Foo{
		Name:"hang san",
		Age: 20,
		Sex: "Male",
		Aaa: 30,
		Bbb: "BBB",

	}

	jsonMe,_ := json.Marshal(me)
	fmt.Println("jsonMe:",jsonMe)
	ccc:=reflect.TypeOf(jsonMe)
	fmt.Println(ccc)
	fmt.Println("stringme:", string(jsonMe))
	fmt.Println("me:", me)
	fmt.Println("===========")
	data:="{\"name\":\"张三\",\"Age\":18,\"High\":true,\"Sex\":\"男\",\"CLASS\":{\"naME\":\"1班\",\"GradE\":3}}"
	fmt.Println(reflect.TypeOf(data))
	str:=[]byte(data)
	str_2:=make([]Foo,0)
	str_3:=append(str_2,me)
	fmt.Println("str_3:" ,str_3)
	fmt.Println("str_3_type:",reflect.TypeOf(str_3))
	fmt.Println("me:",me)
	fmt.Println("me_type:",reflect.TypeOf(me))
	fmt.Println("data is :", data)
	fmt.Println("str is :", str)
	he:=Foo{}
	err:=json.Unmarshal(str,&he)
	if err!=nil{
		fmt.Println(err)
	}

	she:=&he
	fmt.Println("pointer:",*she)
	fmt.Println("he is :",he)

}
