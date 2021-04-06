package function

import (
	"bytes"
	"log"

	//"github.com/pkg/errors"
	"net/http"
	"os/exec"
)

func RunBash (cli string,w http.ResponseWriter,) (err string){
	cmd:=exec.Command("/bin/bash","-c",cli)

	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stderr=&stderr
	cmd.Stdout=&stdout

	if err:=cmd.Run();err != nil{
		//return stderr.String()
		//i,err:=w.Write([]byte(stdout.String()))
		log.Printf("run bash err is %s",err)

		//log.Println("err is ",stdout.String())
		return stdout.String()
	}
	//w.Write([]byte(stdout.String()))
	//log.Printf("out is %s",stdout.String())
	log.Println("Run bash Successfully")
	return "nil"
}
