package main

import (
	log "code.google.com/p/log4go"
	"exception/cassandra"
	"exception/function"
	"sync"
)


//to do
//1. time convert
//2. refresh time set to minute
//3. only read the fish 50 lines of the cumulis file (max)

func main() {

	ch := make(chan string)
	wg := &sync.WaitGroup{}
	wg.Add(2)
	// goroutine 1: check TEST env nodes
	file := "./config.conf"
	log.LoadConfiguration("./log.xml")
	defer log.Close()
	go function.TraceFile(ch,file, wg)

	go cassandra.GenJson(ch)


	wg.Wait()
}







