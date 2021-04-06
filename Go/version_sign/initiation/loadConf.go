package initiation

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
)



/*
 Load the keys.json which include:
 mysql account
 mysql IP
 sftp IP
 sftpaccount
 blob salt
 */

type mysql map[string]string
type sftpServer map[string]string


type Config struct {
	Db mysql
	TransFile sftpServer
	Salt string
}

//C is the instance point to Config, it will be read by DB init and Sftp init
var C Config

//This is thr 1st init to load the config.txt
func init (){

	confFile:=flag.String("conf","/tmp/config.txt","initiate sensitive values")
	flag.Parse()

	content,err:=ioutil.ReadFile(*confFile)
	if err != nil{
		fmt.Println("Open conf.txt failed",err)
		panic(err)
	}

	if err=json.Unmarshal(content,&C);err!=nil{
		fmt.Println("unmarshal failed",err)
		panic(err)
	}

	//Remove the config file after Parse
	err=os.Remove(*confFile)
	if err!=nil{
		fmt.Println("Remove config file failed",err)
	}
	fmt.Println("Removed the config file successfully")

	//Generate the values
	mysqlHost:=C.Db["host"]
	mysqUser:=C.Db["username"]
	mysqlPass:=C.Db["password"]
	mysqlPort:=C.Db["port"]

	sftpHost:=C.TransFile["host"]
	sftpUser:=C.TransFile["username"]
	sftpPass:=C.TransFile["password"]

	salt:=C.Salt

	fmt.Printf("mysqlHost is %s,mysqlUser is %s,mysqlPass is %s,mysqlPort is %s,sftpHost is %s,sftpname is %s," +
		"sftPass is %s, salt is %s \n",mysqlHost,mysqUser,mysqlPass,mysqlPort,sftpHost,sftpUser,sftpPass,salt)

	//Connect DB
	//db.Connect(config)

	//Connect SFTP
	//function.ConnectSftp(config)
	fmt.Println("++++I should be the first init, I'm C.++++ ")
}

