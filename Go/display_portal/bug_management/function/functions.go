package function

import (
	"bytes"
	log "code.google.com/p/log4go"
	"encoding/json"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"

    "exception/cassandra"
	//"github.com/aws/aws-sdk-go/aws/endpoints"

	"io/ioutil"
	"os"
)

// Define config


type felldl map[string] string


type Config struct {
	Nodes felldl
	Cass_Node string
	Table string
	GKStage string
	GKTest string
	USERStage string
	USERTest string
	Refresh int
}

// time format
const layout="2006-01-02 15:04:05"

//Init is used to read the configuration file
func InitConfigFile (config_file string) (conf Config){
	_, err := os.Stat(config_file)
	if err != nil {
		//fmt.Println(fileinfo.Name(),fileinfo.Size())
		fmt.Println("No config file")
	}
	// Get config
	if file, err := os.OpenFile(config_file, os.O_RDONLY, 0666); err == nil {

		defer file.Close()

		if contents, err := ioutil.ReadAll(file); err == nil {
			log.Debug("Read %s file successfully\n", config_file)
			//fmt.Println("contents is:", string(contents))
			if err:=json.Unmarshal(contents, &conf); err == nil {
				log.Debug("Umarshal configuration file Successfully" )
			} else {

				log.Error(err)
				panic("Umarshal configuration file failed, Exit main process!")
			}

		} else {
			log.Error("Failed to Read confg from %s: %s", config_file, err)
		}
	}else {
		log.Error("Open %s failed: %s", config_file, err)
	}

	return
}

var count = 0
func RunBash(command string) (output string){
	loop:
        count=count+1
	var stdOut, stdErr bytes.Buffer
	cmd := exec.Command("/bin/bash", "-c", command)
	cmd.Stdout = &stdOut
	cmd.Stderr = &stdErr

	if err := cmd.Run(); err != nil {
		fmt.Println( "Run Bash script failed: %s : %s,rollback and run again(%s)", fmt.Sprint( err ), stdErr.String(),count )
		goto loop
	}else {
		output = stdOut.String()
	}
    return
}


func ParseTimestamp (time_stamp int64, tz string) (time_cst string) {

	// loc is the time.*Location type "Asia/Shanghai""
	loc,_:=time.LoadLocation(tz)
	//fmt.Println("timestap is ", time_stamp)

	// time_utc is to trnfer int64(15777777) to "2019-01-01:01:01:01"" (UTC)
	// if you run this function on a CST timezone machine, the time_utc is cst
	// but time.Unix is default to consider it is UTC time even it is a cst time
	// so if you transfter time_utc to cst, it will add 8 hours, it is definetely wrong
	// so the program must run on a UTC time zone machine

	time_utc := time.Unix(time_stamp,0).Format(layout)
	t, _ :=time.Parse(layout,time_utc)

	// set loc to tz:= "Asia/Shanghai"
	t=t.In(loc)
	time_cst = t.Format(layout)
	//log.Debug("The cumulis out file is modified at cst %s: ", time_cst)
	//time_cst_tmp, _:=time.ParseInLocation(layout,time_utc,loc)
	//time_cst:= time_cst_tmp.Format(layout)


	//fmt.Println("loc is ",reflect.TypeOf(time_cst_tmp))
	//fmt.Println("time_utc is", time_utc)
	//fmt.Println("time_cst",time_cst_tmp)
	return
}

var m = map[string]string {
	"FE-A": "172.31.2.224",
	"FE-B": "172.31.22.43",
	"LL-A": "172.31.14.7",
	"LL-B": "172.31.30.198",
	"DL-A": "172.31.7.221",
	"DL-B": "172.31.16.151",
	"FE-a": "10.81.74.135",
	"FE-b": "10.81.74.136",
	"LL-a": "10.81.74.137",
	"LL-b": "10.81.74.138",
	"DL-a": "10.81.74.139",
	"DL-b": "10.81.74.140",
}

func GetHost (m map[string]string, ip string) (host string, ok bool) {
	for k,v:= range m {
		if v == ip {
			host = k
			ok = true
			return
		}
	}
	return
}

// this function is to get and save timestamp for each node
// the map is {"IP": timestamp} which can make the timestamp is unique for each node
// step 1: get the mtime of out file
// step 2: seach the map, if it can find the match ip (key), then BREAK and return the last_time ,
// if it can't find the ip which means this the very fisrt startup, then save the new_time as the value of the ip.


func GetTimeStamp ( m2 map[string]int64, ip string, new_time int64) (last_time int64) {

	if len(m2) ==0 {
		m2[ip] = new_time
		//fmt.Println("empty map, saved -> ,",ip,last_time)
		return
	}
	for k, v := range m2 {
		if k == ip {
			last_time = v
			m2[ip] = new_time
			//fmt.Println("found the IP and last_time, new_time!,",k,last_time,new_time)
			// you can't use beak below, break just exit the for loop, we need it exit the function
			return
		}

	}
	// if reach below, means didn't find the ip-time match from the map,
	// then it is a new node, append it in the map.
	//fmt.Println("Didn't find the key, save it:", ip, new_time)
	m2[ip] = new_time
	//fmt.Println("the ip_timestamp map is: ", m2)
	return
}


func TraceFile(ch chan string,file string, wg *sync.WaitGroup){

	defer wg.Done()
	// Initiate the conf file to get all the parameters
	conf := InitConfigFile(file)
	// Get parameters
	nodelist:= conf.Nodes
	table:=conf.Table
	var gk,user string

	// if you set the duration to 1, it is ns by default
	refresh_ns:=conf.Refresh
	refresh_s:=refresh_ns*1000000000
	refresh:=time.Duration(refresh_s)

	//for k,v := range conf.Nodes {
	//	fmt.Printf("k is %s, v is %s\n",k,v)
	//}

	// define an empty map to save {"ip": last_time}
	Ip2LastTime := map[string]int64{}

	for {

		// loop nodelist(map),layer is FE , iplist is 127.0.0.1,127.0.0.1p
		for layer_env, iplist := range nodelist {

			layer := strings.Split(layer_env,"-")[0]
			env := strings.Split(layer_env,"-")[1]

			if env == "stage"{
				gk=conf.GKStage
				user=conf.USERStage
			} else if env == "test" {
				gk = conf.GKTest
				user = conf.USERTest
			} else {
				panic("Undefined layer_env struct.")
			}

			//fmt.Printf("Checking %s, %s..\n",env,layer)

			// loop iplist(string), use strings.Split to convert iy to slice.
			for _, ip := range strings.Split(iplist,",") {
				//fmt.Printf("IP: %s\n",ip)

				// set ssh command
				command := fmt.Sprintf("./bin/GetStat.sh %s %s %s %s", user,gk,ip,layer)

				// file_info is the command return
				file_stat := RunBash(command)
				//fmt.Println("aa",file_stat)

				// calculate mtime and size
				size := strings.Split(file_stat, " ")[2] + " byte"

				//mtime_temp is a string, we need a int64 type timestamp

				mtime_temp := strings.Split(file_stat, " ")[13]
				mtime_stamp, _ := strconv.ParseInt(mtime_temp, 10, 64)

				//log.Debug("mtime(CST) is %d, size is %s", mtime_stamp,size)

				// assgin the mtime_stamp to mtime_last which is used to compare if the mtime is changed
				// when the function startup, the mtime_stamp will defenitely > mtime_last (10000), but it
				// shouldn't consider as the "modified file" if its size is 0.
				// the initial timestamp is 0
				mtime_last := GetTimeStamp(Ip2LastTime,ip, mtime_stamp)
				//fmt.Printf("the last time is: %v\n", mtime_last)

				if mtime_stamp > mtime_last && size != "0 byte" {

					// step 0: get the hostname according to the ip
					host, ok := GetHost(m, ip)
					if !ok {
						log.Error("No host match the IP.")
					}

					// step1: if the file is modified and size > 0 then Parse time to get the cst time
					tz := "Asia/Shanghai"
					time_cst := ParseTimestamp(mtime_stamp, tz)
					//fmt.Println("CST is:",host,time_cst)
					log.Debug("last time is %d, current time is %d, date is %s.", mtime_stamp,mtime_last,time_cst)
					//log.Debug("%s :Found Modify ! at %s, file_size is %s.", host, time_cst, size)

					// step2: if the file is modified then get the file content
					command2 := fmt.Sprintf("./bin/SortFile.sh %s %s %s %s", user, gk, ip, layer)

					// file_info is the command return
                                        exceptiontemp := RunBash(command2)
					exception:= strings.Replace(exceptiontemp,"\n","<br/>",-1)
					//fmt.Println("bb", exception)

					//*****check if the record is alreday in database.
					//***** in case that weite duplicate record into cassandra
					//****** if restart the programe
					c:=cassandra.CheckRecod(time_cst,env,host)
					fmt.Println("count is ",c)
					if c == 0 {
						// Get the empowerthings version
						command3 := fmt.Sprintf("./bin/GetVersion.sh %s %s %s %s", user, gk, ip, layer)
						version := RunBash(command3)
						//fmt.Println("version is ",version)

						//^^^^^^^^^^^^ Write the data into Cassandra ^^^^^^^^
						CassandraSession := cassandra.Session

						cassandra.InserException(table, time_cst, version, exception, env, host)
						defer CassandraSession.Close()
						//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
						// fmt.Println("I will send something to channel.................")
						//close(ch)
						//fmt.Println("I started again!!!!!!!")
					}else {
						fmt.Println("Alreday exsit the record, count is: ",c)
					}
					//***********
				} else if mtime_stamp < mtime_last {
					log.Error("The new mtime_stamp is wrong, it should bigger than the previous one")
				} else if mtime_stamp == mtime_last {
					log.Info("File is not modified, pass.")
				} else if mtime_stamp > mtime_last && size == "0 byte"{
					log.Info("%s :Empty file, 1st time startup",ip)
				} else {
					log.Error("Undefined error happened when compare time_stamp")
				}
			}
		}
		fmt.Printf("Next run after %s\n.", refresh)
                //fmt.Printf("Triger Gen json")
                ch <- "Start Gen"
		time.Sleep(refresh)
	}
}

