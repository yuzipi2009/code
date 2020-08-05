package config

import (
	"./config"
	log "code.google.com/p/log4go"
	"fmt"
	"sync"
	"time"
)

var file= "Go/exception/config_test.conf"
//to do
//1. time convert
//2. refresh time set to minute
//3. only read the fish 50 lines of the cumulis file (max)

func main() {
	log.LoadConfiguration("Go/exception/log.xml")
	//defer log.Close()
	conf := config.InitConfigFile(file)
	// Get parameters
	nodelist:= conf.Nodes
	//fe:=conf.Nodes.FE
	//ll:=conf.Nodes.LL
	//dl:=conf.Nodes.DL
	dir:=conf.Location
	//gk:=conf.GK
	user:=conf.USER

	// if you set the duration to 1, it is ns by default
	refresh_ns:=conf.Refresh
	refresh_s:=refresh_ns*1000000000
	refresh:=time.Duration(refresh_s)

	for k,v := range conf.Nodes {
		fmt.Printf("k is %s, v is %s\n",k,v)
	}
	//fmt.Println(conf)
	//refresh:=time.Duration(refresh_temp)

	//log.Debug("Initiate Cloud parameters:\n FE: %s,%s,\n LL: %s,%s,\n DL: %s,%s,\n Work_dir is %s,\n GK is %s,\n RefreshTime is %ds\n",fe1,fe2,ll1,ll2,dl1,dl2,dir,gk,refresh_s)

	wg := &sync.WaitGroup{}
	wg.Add(1)
	// run goroutine
	go config.TraceFile(user, dir,nodelist, refresh, wg)
	wg.Wait()

}







