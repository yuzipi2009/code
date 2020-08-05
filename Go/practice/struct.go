package main

import (
	"fmt"
	"reflect"
)

type Project struct {}

var p = Project{}
func main ()  {

	fmt.Println(reflect.TypeOf(p))
	fmt.Println(reflect.ValueOf(p))

}