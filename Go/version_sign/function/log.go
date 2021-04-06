package function

import (
	"log"
	"os"
)

func init() {
	Logfd, err := os.OpenFile("/data/var/log/sign.log", os.O_RDWR | os.O_CREATE | os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("error opening file: %v", err)
	}


	//log.SetPrefix("TRACE: ")
	//log.SetFlags(log.Ldate | log.Lmicroseconds | log.Llongfile)
	log.SetFlags(log.Ldate | log.Llongfile)
	log.SetOutput(Logfd)
}

