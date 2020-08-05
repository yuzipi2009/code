package config

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
	Location string
	GK string
	USER string
	Refresh int
}

// time format
const layout="2006-01-02 15:04:05"

//Init is used to read the configuration file
func InitConfigFile (config_file string) (conf Config){
    //conf:=Config{}
	//var fileinfo os.FileInfo
	//cmd:=exec.Command("/bin/bash" , "-c" ,`ls Go/exception`)
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
func GetFileContent(remote, local string) (output string){

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


func TraceFile(user,dir string, nodelist felldl, refresh time.Duration, wg *sync.WaitGroup){

	defer wg.Done()
	for {
		// loop nodelist(map),layer is FE , iplist is 127.0.0.1,127.0.0.1p
		for layer, iplist := range nodelist {
			fmt.Printf("Checking %s......\n",layer)

			// loop iplist(string), use strings.Split to convert iy to slice.
			for _, ip := range strings.Split(iplist,",") {
				fmt.Printf("IP: %s\n",ip)

				// set ssh command
				auth := fmt.Sprintf("%s@%s", user, ip)
				command := fmt.Sprintf("if [ -f %s/foo.txt ]; then stat -t %s/foo.txt ; else echo \"[Error] no file\";fi", dir, dir)

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
				var mtime_last int64 = 100000
				if mtime_stamp > mtime_last {
				mtime_last = mtime_stamp

					// step1: if the file is modified then Parse time to get the cst time
					tz := "Asia/Shanghai"
					time_cst := ParseTimestamp(mtime_stamp, tz)
					log.Debug("File is modified at %s, file_size is %s.", time_cst, size)

					// step2: if the file is modified then get the file content
					command = fmt.Sprintf("%s:%s/foo.txt", auth, dir)
					local := "Go/exception/repository"
					GetFileContent(command, local)

					// step3: Read the file content
					// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
					outfile := local + "/foo.txt"
					if f, err := os.OpenFile(outfile, os.O_RDONLY, 0666); err == nil {

						defer f.Close()

						if content, err := ioutil.ReadFile(outfile); err == nil {
							log.Debug("Read %s cumulis out file successfully\n", outfile)
							log.Info("The content of the cumulis file is : \n%s", string(content))
							//log.Info("cumulis_out file contents is:\n", string(content))
						} else {
							log.Error("Failed to Read out file from %s: %s", outfile, err)
						}
					} else {
						log.Error("Open out file %s failed: %s", outfile, err)
					}
					// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

				} else if mtime_stamp < mtime_last {
					log.Error("The new mtime_stamp is wrong, it should bigger than the previous one")
				} else if mtime_stamp == mtime_last {
					log.Info("File is not modified, keep the same time_stamp.")
				} else {
					log.Error("Undefined error happened when compare time_stamp")
				}

			}
		}
		fmt.Printf("Next run after %s\n.", refresh)
		time.Sleep(refresh)
	}
}

