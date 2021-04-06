package function

import (
	"encoding/json"
	"net/http"
)

func Response (c int,err error,l string,) []byte{
	type playload struct {
		Code int `json:"code"`
		Error error `json:"error"`
		Location string `json:"location"`
	}

	var p playload
	p.Code = c
	p.Error = err
	p.Location = l
	resp, _ := json.Marshal(p)

	return resp
}

// this function is used to generate response body
func GenResponse (c int,m string,writer http.ResponseWriter){
	r.Code=c
	r.Message=m
	json,err:=json.Marshal(r)
	if err!=nil{
		writer.Write(json)
	} else {
		writer.Write(json)

	}
}
