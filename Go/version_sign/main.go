package main

import (
	_ "github.com/go-sql-driver/mysql"
	"version_sign/function"
	//_ "github.com/gocql/gocql"
	"version_sign/db"

)
//////////////////////Main///////////////////////

func main () {

    defer db.ProjectsHandler.Close()
    defer db.SignatureHandler.Close()
	defer function.SftpClient.Close()
	//Http server
	function.HandleRequests()

}