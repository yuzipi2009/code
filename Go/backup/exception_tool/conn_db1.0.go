package cassandra

import (
	"fmt"
	"github.com/gocql/gocql"
)
var Session *gocql.Session
func init () {
	var err error
	con := gocql.NewCluster("10.81.74.17")
	con.Authenticator = gocql.PasswordAuthenticator{
		Username: "cassandra",
		Password: "cassandra",
	}
	con.ProtoVersion = 4
	con.Keyspace = "kaios_sh"
	Session,err = con.CreateSession()
	if err != nil {
		panic(err)
	}
	fmt.Println("cassandra init done")

}

