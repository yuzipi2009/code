package main

import (
	"fmt"
	"reflect"
)


type secret struct {
	Pid string
	Project_name string
	Odm_name string
	Prvk string
}

type prvk_location struct {
	Pid string
	Rootkey string
	Imagekey string
}

type sign_history struct {
	Pid string
	Project_name string
	Odm_name string
	Signed bool
}

func CreateQuery (table interface{}){
	if reflect.ValueOf(table).Kind() == reflect.Struct{
		t:=reflect.TypeOf(table)
		v:=reflect.ValueOf(table)
		tableName:=t.Name()
		length:=t.NumField()
		query:=fmt.Sprintf("insert INTO %s(",tableName)
		query2:=fmt.Sprintf(" values(")

		//with below loop, we can get:
		//"insert into prvk_location(pid,rootKey,imageKey) values("
		for i:=0;i<length;i++{
			field:=t.Field(i).Name
			value:=v.Field(i)
			if i==0 {
				query = fmt.Sprintf("%s%s",query,field)
				query2 = fmt.Sprintf("%s\"%s\"",query2,value)
			} else{
				query = fmt.Sprintf("%s,%s",query,field)
				query2 = fmt.Sprintf("%s, \"%s\"",query2,value)
			}
		}
		query=fmt.Sprintf("%s)",query)
		query2=fmt.Sprintf("%s)",query2)
		fullQuery:=query + query2
		fmt.Println("full is ",fullQuery)
	}

}

func main ()  {

	s:=secret{
		Pid: "200",
		Project_name: "Blue",
		Odm_name: "RED",
		Prvk: "xxxxxxaaaaaaaaaaa",
	}
	CreateQuery(s)

}