package main

import (
	"bytes"
	"fmt"
	"os/exec"
)

func GetFileInfo(auth, command string) (output string){

	var stdOut, stdErr bytes.Buffer
	cmd := exec.Command( "ssh", auth, command )
	cmd.Stdout = &stdOut
	cmd.Stderr = &stdErr

	if err := cmd.Run(); err != nil {
		fmt.Printf( "Get cumulilis out file info failed: %s : %s", fmt.Sprint( err ), stdErr.String() )
	}

	output =stdOut.String()
	return
}

func main (){
	// set ssh command
	user:="kai-user"
	gk:= "10.81.76.19"
	//dir:= "/tmp"
	//layer:= "fe3"
	ip:= "10.81.74.135"
	auth := fmt.Sprintf("%s@%s", user, gk)
	//filename:= fmt.Sprintf( "%s/text_%s.txt",dir,layer)
	command := fmt.Sprintf("\"ssh %s 'bash -c ls'\"", ip)

	fmt.Println("ssh",auth,command)
	//return
	// file_info is the command return
	file_info := GetFileInfo(auth, command)
	fmt.Println("aa",file_info)

}

