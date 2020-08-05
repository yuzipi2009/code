
package main

import (
	"fmt"
	"reflect"
)

type order struct {
	ordId      int
	customerId int
	id3 int
	id4 int
}

type employee struct {
	name    string
	id      int
	address string
	salary  int
	country string
}

func createQuery(q interface{}) {
	if reflect.ValueOf(q).Kind() == reflect.Struct {
		t := reflect.TypeOf(q).Name()
		fmt.Println("t is ",t)
		query := fmt.Sprintf("insert into %s values(", t)
		v := reflect.ValueOf(q)
		for i := 0; i < v.NumField(); i++ {
			switch v.Field(i).Kind() {
			case reflect.Int:
				if i == 0 {
					query = fmt.Sprintf("%s%d", query, v.Field(i).Int())
				} else {
					query = fmt.Sprintf("%s, %d", query, v.Field(i).Int())
				}
			case reflect.String:
				if i == 0 {
					query = fmt.Sprintf("%s\"%s\"", query, v.Field(i).String())
				} else {
					query = fmt.Sprintf("%s, \"%s\"", query, v.Field(i).String())
				}
			default:
				fmt.Println("Unsupported type")
				return
			}
		}
		query = fmt.Sprintf("%s)", query)
		fmt.Println(query)
		return

	}
	fmt.Println("unsupported type")
}

func x (o interface{}) {
	fmt.Println(reflect.TypeOf(o).NumField())
	fmt.Println(reflect.TypeOf(o).Name())
	fmt.Println(reflect.TypeOf(o).Kind())
	fmt.Println(reflect.TypeOf(o).Size())
	fmt.Println(reflect.TypeOf(o).Field(1))
	fmt.Println(reflect.ValueOf(o).Field(1))

}

func CreateSelect (table interface{}){
	if reflect.ValueOf(table).Kind() == reflect.Struct{
		t:=reflect.TypeOf(table)
		v:=reflect.ValueOf(table)
		tableName:=t.Name()
		primaryKey:=t.Field(0).Name
		primaryValue:=v.Field(0)
		fmt.Println("primaryKey is ",primaryKey)
		length:=t.NumField()
		query:=fmt.Sprintf("select ")
		query2:=fmt.Sprintf(" from %s where %s = %d",tableName,primaryKey,primaryValue)

		//with below loop, we can get:
		//query= "insert into prvk_location(pid,rootKey,imageKey)"
		//query2="values("200", "Blue", "RED", "xxxxxx")"

		//the reason i start from 1 is because 0 is the primaryKey, no need to query it.
		for i:=1;i<length;i++{
			field:=t.Field(i).Name
				query = fmt.Sprintf("%s,%s",query,field)
		}
		query=fmt.Sprintf("%s",query)
		fullQuery:=query + query2
		fmt.Println("full is ",fullQuery)
	}

}
func main() {
	/*
	o := order{
		ordId:      456,
		customerId: 56,
		id3: 78,
		id4: 910,
	}
	//createQuery(o)

	/*
	e := employee{
		name:    "Naveen",
		id:      565,
		address: "Coimbatore",
		salary:  90000,
		country: "India",
	}
	createQuery(e)
	i := 90
	createQuery(i)
	 */


	//fmt.Println(reflect.ValueOf(o).NumField())

    //CreateSelect(o)
    a:=reflect.TypeOf(employee{})
    length:=a.NumField()
    item:=""
    for l:=0;l<length;l++ {
    	name:=a.Field(l).Name
    	if l==0 {
			item = name
		}else{
			item = item + "," + name

		}
	}
	fmt.Println("item is", item)

}