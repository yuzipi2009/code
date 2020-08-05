package main


// This sample program demonstrates how to use the base log package.

import (
	"fmt"
	"log"
	"os"
)

func init() {
	f, err := os.OpenFile("AAAAAAAA.log", os.O_RDWR | os.O_CREATE | os.O_APPEND, 0666)
	if err != nil {
		log.Fatalf("error opening file: %v", err)
	}
	//defer f.Close()

	//log.Println("This is a test log entry")

	log.SetPrefix("TRACE: ")
	log.SetFlags(log.Ldate | log.Lmicroseconds | log.Llongfile)
	log.SetOutput(f)
}

func main() {
	fmt.Println("???")
	// Println writes to the standard logger.
	log.Println("message")
	fmt.Println("??xxxx?")

	// Fatalln is Println() followed by a call to os.Exit(1).
	log.Fatalln("fatal message")

	// Panicln is Println() followed by a call to panic().
	log.Panicln("panic message")
	fmt.Println("???")
}