package main

import "fmt"

// Define variables
const user = "iot-user"
const prod_gk = "34.228.28.86"
const prod_cass = "172.31.4.248"
const env = "kaicloud"
const cass_bin = "/data/tools/repository/apache-cassandra/bin"

var Query_App2 = fmt.Printf("ssh %s@%s "ssh %s \"sudo su - cassadmin -c \\\"rm -rf /tmp/app_version.csv && ${cass_bin}/cqlsh -e \\\\\\\"copy ${env}.app_version to '/tmp/app_version.csv' with header=true and null='<null>' \\\\\\\" && chmod 755 /tmp/app_version.csv \\\"\"")


// Fetch tables




// import tables





// connect to cassandra


// fetch data


// generate json


// copy to server



