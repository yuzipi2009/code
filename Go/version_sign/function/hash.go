package function

import (
	"crypto/sha1"
	"encoding/hex"

)


func Hash(obj string) string{

	h := sha1.New()

	h.Write([]byte(obj))

	bs := h.Sum(nil)
	//log.Printf("bs is %x\n",bs)
	stringhash:=hex.EncodeToString(bs)

	return  stringhash

}