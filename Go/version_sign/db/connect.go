package db

import "C"
import (
	"database/sql"
	"fmt"
	_ "github.com/go-sql-driver/mysql"
	_ "github.com/gocql/gocql"
	"log"
	"time"
	"version_sign/initiation"
)


const (
	CHARSET   = "utf8"
)

var ProjectsHandler *sql.DB
var SignatureHandler *sql.DB

var Perr error
var Serr error

//This is thr 3rd init to connect to cassandra
func init() {

	const CHARSET   = "utf8"

	DbEproject := "operators"
	DbSignature:="signature"


	HOST:=initiation.C.Db["host"]
	USER_NAME:=initiation.C.Db["username"]
	PASS_WORD:=initiation.C.Db["password"]
	PORT:=initiation.C.Db["port"]

	projects := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=%s", USER_NAME, PASS_WORD, HOST, PORT, DbEproject, CHARSET)
	signature := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=%s", USER_NAME, PASS_WORD, HOST, PORT, DbSignature, CHARSET)
	// Connect
	ProjectsHandler, Perr = sql.Open("mysql", projects)
	SignatureHandler,Serr = sql.Open("mysql", signature)

	//defer ProjectsHandler.Close()
	//defer SignatureHandler.Close()

	if Perr != nil || Serr !=nil {
		panic("Configure wrong: " + Perr.Error() + Serr.Error())
	}

	// max connect number
	ProjectsHandler.SetMaxOpenConns(100)
	SignatureHandler.SetMaxOpenConns(100)

	// max idel number
	ProjectsHandler.SetMaxIdleConns(20)
	SignatureHandler.SetMaxIdleConns(20)

	// max connect cycle
	ProjectsHandler.SetConnMaxLifetime(100*time.Second)
	SignatureHandler.SetConnMaxLifetime(100*time.Second)
    log.Println("Conencted ......")

	if projectErr := ProjectsHandler.Ping(); nil != projectErr {
		panic("Coneect failed: " + projectErr.Error())
	}
	if signErr := SignatureHandler.Ping(); nil != signErr {
		panic("Coneect failed: " + signErr.Error())
	}
	log.Println("Conencted to mysql")
	fmt.Println("++++I should be the 3rd init, I'm DB.++++ ")
}

