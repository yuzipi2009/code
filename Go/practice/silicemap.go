package main

import (
	"encoding/json"
	"fmt"
)

type notifyOne struct {
	Next_pay_dl int
}

func main()  {
	imeimap:=map[string]int{"360101540012341":1569540362,"3901015400174738":1569540362,"3901028282821":1569540363,"390101540012341":1569540364}

	sliceNotify:=make([]map[string]notifyOne,0)
	mapNotify:=make(map[string]notifyOne,0)

	n:=notifyOne{}
	for k,v:=range imeimap{
		fmt.Printf("k is %s, v is %v\n",k,v)
		n.Next_pay_dl=v
		mapNotify[k]=n
		sliceNotify=append(sliceNotify,mapNotify)
		fmt.Printf("mapNotify is %+v\n",mapNotify)
	}
	fmt.Printf("sliceNotify is %v\n",sliceNotify)
	byte,err:=json.Marshal(sliceNotify)
	if err!=nil{
		fmt.Println(err)
	}
	fmt.Println(string(byte))
}