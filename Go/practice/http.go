package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
)

func Ping() (err error) {

	client := &http.Client{}

	var url_buf bytes.Buffer

	url:="http://test.kaiostech.com"
	url_buf.WriteString(url)
	url_buf.WriteString("/gettime")
	fmt.Println("url_string is ",url_buf.String())

	req, err := http.NewRequest("GET", url_buf.String(), nil)
	fmt.Println("req is",req)

	if err != nil {
		return err
	}

	req.Close=true

	//s3.Signer.Sign(req,nil,s3.Region,s3.Service)

	//http_client:=http.Client{
	//	Timeout:5,
	//}

	r, err := client.Do(req)

	if err != nil {
		//log.Printf("http error: %s", err)
		fmt.Println( err)
	}

	defer r.Body.Close()

	resultbody, _ := ioutil.ReadAll(r.Body)
	fmt.Println("r is ",r)
	fmt.Println("r.Header is ",r.Header)
	fmt.Println("r.Body is ",r.Body)


	if r.StatusCode != 200 {
		//log.Printf("error, status = %d", r.StatusCode)
		//log.Printf("error response: %s", resultbody)
		return fmt.Errorf("error code %d. response: %s", r.StatusCode, resultbody)
	}

	return nil
}

func main ()  {
	Ping()
}