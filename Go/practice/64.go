package main


import (
	"encoding/base64"
	"fmt"
	"log"
	"reflect"
)

func main() {
	s := "Hello World!"
	b := []byte(s)

	sEnc := base64.StdEncoding.EncodeToString(b)
	log.Printf("enc=[%s]\n", sEnc)

	sDec, err := base64.StdEncoding.DecodeString(sEnc)
	if err != nil {
		log.Printf("base64 decode failure, error=[%v]\n", err)
	} else {
		log.Printf("dec=[%s]\n", sDec)
		fmt.Println(reflect.TypeOf(sDec))
	}
}
