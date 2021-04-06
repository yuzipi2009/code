package db

import (
"encoding/base64"
"log"
)

func Encode(s string) (code64 string){
	b := []byte(s)

	sEnc := base64.StdEncoding.EncodeToString(b)
	//log.Printf("enc=[%s]\n", sEnc)
	return sEnc
}

func Decode (s string) {
	sDec, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		log.Printf("base64 decode failure, error=[%v]\n", err)
	} else {
		log.Printf("dec=[%s]\n", sDec)
	}
}
