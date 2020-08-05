package main


import (
"encoding/json"
	"fmt"
)

func EditResponse (c int,message string)  {
	type playload struct {
		Code int `json:"code"`
		Response string `json:"response"`
	}

	var p playload
	p.Code=c
	p.Response=message

	body,err:=json.Marshal(p)
	if err!=nil{
		fmt.Println("marshal failed",err)
	}
	fmt.Println("body is ",string(body))
}

type  Customer struct {
	Id int `json:"id"`
	Name string `json:"name"`
}

func  B (c Customer){
	c.Id=1000000
}
func main()  {
	//message:="ok"
	//EditResponse(200,message)


	//customer := new(Customer)
	customer:=Customer{Id:500,Name:"CCC"}
	fmt.Printf("customer :%T\n",customer)
	customer.Id=100
	customer.Name="aaa"
	fmt.Println("1st customer",customer)

	customer.Id=200
	customer.Name="bbb"
	fmt.Println("2nd customer",customer)

	B(customer)
	customer.Id=10000
    fmt.Println("3rd customer",customer)

}