package main

import (
	"exception/cassandra"
	"exception/function"
	"fmt"
	"sync"
	cassan
	log "code.google.com/p/log4go"
)

//to do
//1. time convert
//2. refresh time set to minute
//3. only read the fish 50 lines of the cumulis file (max)

func main() {


	//cassandra.GenJson()
	//return
	a := cassandra.CheckRecod("2019-12-02 20:21:42", "stage", "FE-A")
	fmt.Println(a)
	//returnd
	ch := make(chan string)
	wg := &sync.WaitGroup{}
	wg.Add(2)
	// goroutine 1: check TEST env nodes
	file := "Go/src/exception/config.conf"
	log.LoadConfiguration("Go/src/exception/log.xml")
	defer log.Close()
	go function.TraceFile(ch, file, wg)

	go cassandra.GenJson(ch)

	wg.Wait()
}
