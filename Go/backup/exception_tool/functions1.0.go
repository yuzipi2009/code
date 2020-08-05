

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
	//FE string
	//LL string
	//DL string


type Config struct {
	Nodes felldl
	Cass_Node string
	Location string
	GK string
	USER string
	Refresh int
}

// time format
const layout="2006-01-02 15:04:05"

//Init is used to read the configuration file
func InitConfigFile (config_file string) (conf Config){
    //conf=Config{}
	//var fileinfo os.FileInfo
	//cmd:=exec.Command("/bin/bash" , "-c" ,`ls Go/src/exception/log.xml `)
	//var out bytes.Buffer
	//var error bytes.Buffer
	//cmd.Stdout = &out
	//cmd.Stderr = &error
	//cmd.Run()
	//fmt.Println(out.String())
	//fmt.Println(error.String())

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
				log.Error("Umarshal configuration file failed: ",err)
			}

		} else {
			log.Error("Failed to Read confg from %s: %s", config_file, err)
		}
	}else {
		log.Error("Open %s failed: %s", config_file, err)
	}

	return
}

//func (conf *Config)  GetFE () []string {
//	temp := strings.Split(conf.FE, ",")
//	return temp
//	fmt.Println("type is", reflect.TypeOf(temp))
//}

//func (conf *Config)  GetLL () []string {
//	temp := strings.Split(conf.LL, ",")
//	return temp
//}

//func (conf *Config)  GetDL () []string {
//	temp := strings.Split(conf.DL, ",")
//	return temp
//}


func GetFileInfo(auth, command string) (output string){

	var stdOut, stdErr bytes.Buffer
	cmd := exec.Command( "ssh", auth, command )
	cmd.Stdout = &stdOut
	cmd.Stderr = &stdErr

	if err := cmd.Run(); err != nil {
		log.Error( "Get cumulilis out file info failed: %s : %s", fmt.Sprint( err ), stdErr.String() )
	}

    output =stdOut.String()
    return
}

func CopyFileLocal(remote, local string) (output string){

	var stdOut, stdErr bytes.Buffer
	cmd := exec.Command( "scp", remote, local )
	cmd.Stdout = &stdOut
	cmd.Stderr = &stdErr

	if err := cmd.Run(); err != nil {
		log.Error( "Scp file failed: %s : %s", fmt.Sprint( err ), stdErr.String() )
	}

    output =stdOut.String()
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
"FE-a":"10.81.74.17",
"FE-b":"10.81.74.18",
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
		fmt.Println("empty map, saved -> ,",ip,last_time)
		return
	}
	for k, v := range m2 {
		if k == ip {
			last_time = v
			m2[ip] = new_time
			fmt.Println("found the IP and last_time, new_time!,",k,last_time,new_time)
			break
		}
			fmt.Println("Didn't find the key, save it:", ip, new_time)
			m2[ip] = new_time
	}
	fmt.Println("the ip_timestamp map is: ", m2)
	return
}


func TraceFile(user,dir string, nodelist felldl, refresh time.Duration, wg *sync.WaitGroup){

	defer wg.Done()

	// define an empty map to save {"ip": last_time}
	Ip2LastTime := map[string]int64{}

	for {

		// loop nodelist(map),layer is FE , iplist is 127.0.0.1,127.0.0.1p
		for layer, iplist := range nodelist {
			fmt.Printf("Checking %s......\n",layer)

			// loop iplist(string), use strings.Split to convert iy to slice.
			for _, ip := range strings.Split(iplist,",") {
				fmt.Printf("IP: %s\n",ip)

				// set ssh command
				auth := fmt.Sprintf("%s@%s", user, ip)

				filename:= fmt.Sprintf( "%s/cumulis_%s.out",dir,layer)
				command := fmt.Sprintf("ssh %s \"if [ -f %s ]; then stat -t %s  ; else echo \"[Error] no file\";fi\"", ip,filename,filename)

				// file_info is the command return
				file_info := GetFileInfo(auth, command)
				//fmt.Println("aa",file_info)

				// calculate mtime and size
				size := strings.Split(file_info, " ")[2] + " byte"

				//mtime_temp is a string, we need a int64 type timestamp

				mtime_temp := strings.Split(file_info, " ")[13]
				mtime_stamp, _ := strconv.ParseInt(mtime_temp, 10, 64)

				//log.Debug("mtime(CST) is %d, size is %s", mtime_stamp,size)

				// assgin the mtime_stamp to mtime_last which is used to compare if the mtime is changed
				// when the function startup, the mtime_stamp will defenitely > mtime_last (10000), but it
				// shouldn't consider as the "modified file" if its size is 0.
				// the initial timestamp is 0
				mtime_last := GetTimeStamp(Ip2LastTime,ip, mtime_stamp)
				fmt.Printf("the last time is: %v\n", mtime_last)

				if mtime_stamp > mtime_last && size != "0 byte"{
					// step 0: get the hostname according to the ip
					host, ok :=GetHost(m,ip)
					if !ok {
						log.Error("No host match the IP.")
					}

					// step1: if the file is modified and size > 0 then Parse time to get the cst time
					tz := "Asia/Shanghai"
					time_cst := ParseTimestamp(mtime_stamp, tz)
					log.Debug("%s :Found Modify ! at %s, file_size is %s.", host,time_cst, size)

					// step2: if the file is modified then get the file content
					command = fmt.Sprintf("%s:%s", auth, filename)
					local := "/data/var"
					CopyFileLocal(command, local)

					// step3: Read the file content
					// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					backup := local + "/exception.txt"
					if f, err := os.OpenFile(backup, os.O_RDONLY, 0666); err == nil {

						defer f.Close()

						if content, err := ioutil.ReadFile(backup); err == nil {
							log.Debug("%s :Read %s cumulis out file successfully\n", host,backup)
							log.Info("%s: The content of the cumulis file is : \n%s", host, string(content))

							//^^^^^^^^^^^^ Write the data into Cassandra ^^^^^^^^
							CassandraSession := cassandra.Session

							cassandra.InserException(time_cst,string(content),host)
							defer CassandraSession.Close()
							//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

						} else {
							log.Error("%s: Failed to Read out file from %s: %s", host, backup, err)
						}
					} else {
						log.Error("%s: Open out file %s failed: %s", host,backup, err)
					}
					// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

				} else if mtime_stamp < mtime_last {
					log.Error("The new mtime_stamp is wrong, it should bigger than the previous one")
				} else if mtime_stamp == mtime_last {
					log.Info("File is not modified, keep the same time_stamp.")
				} else if mtime_stamp > mtime_last && size == "0 byte"{
					log.Info("%s :Empty file, 1st time startup",)
				} else {
					log.Error("Undefined error happened when compare time_stamp")
				}
			}
		}
		fmt.Printf("Next run after %s\n.", refresh)
		time.Sleep(refresh)
	}
}

