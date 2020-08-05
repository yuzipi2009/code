package main

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"os"
)

//this function will return a string of md5check
func md5sum (filepath string){
	src,err:=os.Open(filepath)
	if err != nil {
		log.Println("MD5:Open source error",err)
	}

	h:=md5.New()
	io.Copy(h,src)
	fmt.Println( hex.EncodeToString(h.Sum(nil)))

}

func main(){
	md5sum("/data/var/packages/Waterworld/Erbium-E241S/version.package")
}

