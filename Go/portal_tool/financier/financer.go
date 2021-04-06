package financier

import (
	"bytes"
	"encoding/json"
	"fmt"
	"github.com/pkg/errors"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

//financierServer will have below methods
type FinancierFunction interface {
	Devices(w http.ResponseWriter,curef,imei,tag,now string)
	Ping(w http.ResponseWriter,imei,tag string)
	Notify_paid(w http.ResponseWriter,curef,tag string,dataMap map[string]string,now string)
	Notify_credit_completed(w http.ResponseWriter,curef,tag string,dataMap map[string]string,now string)
}

type FinancierServer struct {}

//the play load for notify_paid api when query one imei
var imei string
type notifyOne struct {
	Next_pay_dl int `json:"next_pay_dl"`
}

//the play load for notify_paid api when query a imei list

var notifyMap map[string]notifyOne
var notifyMapList []map[string]notifyOne

// the playload for notify_credit_complete
type completeOne struct {
	Msg string `json:"msg"`
}

//the playload for notify_credit_complete api when query a imei list
var completeMap map[string]completeOne
var completeMapList []map[string]completeOne

//20200407: I gave up this function , beause I don't know how
//to sumulate test_hawk with this function
func loadToken () (io.Reader,error){
	tokenfile:="/tmp/test_token.json"
	f,err:=os.Open(tokenfile)
	if err!=nil{
		return nil,err
	}

	//reader := bufio.NewReader(f)
	return f,err
}


//Handle Http request
//20200407: I gave up this function , beause I don't know how
//to sumulate test_hawk with this function
func HandleHttp (path, verb string, body io.Reader) {
	dn:="https://api.test.kaiostech.com"
	var sliceUrl = []string {dn,path}
	url:= strings.Join(sliceUrl,"/")

	client := &http.Client{}

	//var url_buf bytes.Buffer
	//url_buf.WriteString(dn)
	//url_buf.WriteString("/")
	//url_buf.WriteString(path)
	//fmt.Println("url_string is ",url_buf.String())

	req, err := http.NewRequest(verb, url, body)
	fmt.Println("req is",req)
	if err != nil {
		fmt.Println("http.NewRequest error",err)
	}

	//req.Close=true

	resp, err := client.Do(req)
	defer resp.Body.Close()

	if err != nil {
		fmt.Println("http.NewRequest error",err)
	}
	//return resp
	//resultbody, _ := ioutil.ReadAll(r.Body)
	//fmt.Println("Proto is ",resp.Proto)
	fmt.Println("Header is ",resp.Header)
	fmt.Println("Body is ",resp.Body)
	fmt.Println("Request is ",resp.Request)
	//fmt.Println("ProtoMajor is ",resp.ProtoMajor)
	//fmt.Println(" TLS is ",resp.TLS)
	//fmt.Println("StatusCode is ",resp.StatusCode)
	//fmt.Println("Status is ",resp.Status)
	resultbody, _ := ioutil.ReadAll(resp.Body)
	fmt.Println("resultbody is ",string(resultbody))
}

func writePlayLoad(now string, data []byte){
	//jsonpath:=fmt.Sprintf("/data/bin/hawk/jwt/inotify_%s.json",now)
	jsonpath:=fmt.Sprintf("/tmp/notify_%s.json",now)
	file,err:=os.OpenFile(jsonpath,os.O_RDWR|os.O_CREATE,os.ModePerm)
	if err!=nil{
		fmt.Printf("Open %s failed:",err)
	}
    defer file.Close()
	_,err2:=file.Write(data)
	if err!=nil{
		fmt.Printf("Write data %s failed:",err2)
	}
}
//devices api is to fetch all the devices linked with the given financier account
//it will fetch the specific device if the imei is given
//otherwise fetch all devices
//There is no playload for this GET API
func (f FinancierServer) Devices(w http.ResponseWriter,curef,imei,tag,now string){
	//imei can be empty, but it must have tag
	if len(imei) == 0{
		runBash(w,curef,tag,now)
	}else {
		runBash(w,curef,imei,tag,now)
	}
}

//This API allows the financier web site to directly communicate with a given device
// to fetch its latest up to date status data.
//There is no playload for this GET API and it MUST have imei for this api
func (f FinancierServer) Ping(w http.ResponseWriter,imei,tag string){
	if len(imei) == 0{
		output:=errors.New("you must specify imei for Ping API").Error()
		w.Write([]byte(output))
	}else {
		runBash(w,imei,tag)

	}
}

//This call is going to create a Payment Notification command to the device in order to
//reschedule the modem lock at the provided new deadline and program the reminder and
//warning deadline in KaiCloud but also eventually into the device.
//if checking one imei, it will return an json with "next_pay_dl":
//1569540362,
// if no imei, you need to create an playload
/*
[
"390101540012341": { "next_pay_dl": 1569540362 },
"390101540075318": { "next_pay_dl": 1579540362 },
"390101540509512": { "next_pay_dl": 1589540362 }
]
 */
func (f FinancierServer) Notify_paid(w http.ResponseWriter,curef,tag string,dataMap map[string]string,now string) {
	//dataMap is a map, {imei:dl}

	notifyMapList=make([]map[string]notifyOne,0)
	n:=notifyOne{}
	len:=len(dataMap)
	if len == 0{
		fmt.Println("The data map is empty, Aborting")
		return
	}
	if len == 1{
		//this is for API3="financier_be/v1.0/devices/${imei}/notify_paid"
		//is imei is given, generate the playlod like: {"next_pay_dl": 1569540362,}
		for k,v:=range dataMap{
			fmt.Printf("k is %s, v is %v",k,v)
			imei = k
			n.Next_pay_dl,_ = strconv.Atoi(v)
		}
		jsondata, _ := json.Marshal(n)
		fmt.Printf("playload is %+v\n",string(jsondata))
		// the bash shell will read the json generated by writePlayLoad
		fmt.Println("imei is ",imei)
		writePlayLoad(now,jsondata)
		runBash(w,curef,imei,tag,now)


	}else if len > 0 {
		/*this is for API4="financier_be/v1.0/devices/notify_paid"
		is imei is not given, generate the playlod like:
		this is list whoes item is just one  map
		[{
			"390101540012341": { "next_pay_dl": 1569540362 },
			"390101540075318": { "next_pay_dl": 1579540362 },
			"390101540509512": { "next_pay_dl": 1589540362 }
		}]
		 */
		notifyMap=make(map[string]notifyOne,0)
		for k,v:=range dataMap{
			imei=""
			fmt.Printf("imei is %s, dl is %s\n",k,v)
			n.Next_pay_dl,_ = strconv.Atoi(v)
			notifyMap[k]=n
			fmt.Printf("map is %+v\n",notifyMap)
		}
		fmt.Printf("final_map is %+v\n",notifyMap)
		notifyMapList=append(notifyMapList,notifyMap)
		fmt.Printf("final_list is %+v\n",notifyMapList)
		jsondata, _ := json.Marshal(notifyMapList)
		fmt.Printf("playload is %+v\n",string(jsondata))
		// the bash shell will read the json generated by writePlayLoad
		writePlayLoad(now,jsondata)
		runBash(w,curef,imei,tag,now)


	}else {
		fmt.Sprintf("Undefiend data map: %v",dataMap)
	}

}


//This call is going to create a Credit Completed Notification command to the device in order
//to deactivate the Financier client and the modem lock once executed.
/* The playload is like :
{
"msg": "Congratulation. Your last payment has been received. Your device has now
been definitely unlocked.",
}
 */
func (f FinancierServer) Notify_credit_completed(w http.ResponseWriter,curef,tag string,dataMap map[string]string,now string){
	//dataMap is a map, {imei:msg}

	completeMapList=make([]map[string]completeOne,0)
	c:=completeOne{}
	len:=len(dataMap)
	if len == 0{
		fmt.Println("The data map is empty, Aborting")
		return
	}
	if len == 1{
		//this is for API5="financier_be/v1.0/devices/${imei}/notify_credit_completed"
		//is imei is given, generate the playlod like: {"msg": Congratulation,}
		for k,v:=range dataMap{
			fmt.Printf("k is %s, v is %v",k,v)
			imei = k
			c.Msg=v
		}
		jsondata, _ := json.Marshal(c)
		fmt.Printf("playload is %+v\n",string(jsondata))
		// the bash shell will read the json generated by writePlayLoad
		writePlayLoad(now,jsondata)
		runBash(w,curef,imei,tag,now)

	}else if len > 0 {
		/*this is forAPI6="financier_be/v1.0/devices/notify_credit_completed"
		is imei is not given, generate the playlod like
		[{
		"390101540012341": { "msg": "Congratulation. Your last payment has been received. Your device has now been
		definitely unlocked." },
		"390101540075318": { "msg": "Congratulation. Your last payment has been received. Your device has now been
		definitely unlocked." },
		"390101540509512": {"msg": "Congratulation. Your last payment has been received. Your device has now been
		definitely unlocked." }
		}]
		*/
		completeMap=make(map[string]completeOne,0)
		for k,v:=range dataMap{
			imei=""
			fmt.Printf("k is %s, v is %s, imei is %s\n",k,v,imei)
			c.Msg = v
			completeMap[k]=c
			fmt.Printf("map is %+v\n",completeMap)
		}
		fmt.Printf("final_map is %+v\n",completeMap)
		completeMapList=append(completeMapList,completeMap)
		jsondata, _ := json.Marshal(completeMapList)
		fmt.Printf("playload is %+v\n",string(jsondata))
		// the bash shell will read the json generated by writePlayLoad
		writePlayLoad(now,jsondata)
		runBash(w,curef,imei,tag,now)

	}else {
		fmt.Sprintf("Undefiend data map: %v",dataMap)
	}

}



func runBash (w http.ResponseWriter,args ... string){

	var command string
	fmt.Println("args is ",args)
	//bashpath:="/data/bin/src/display_tool/financier_test.sh"
	command ="/data/bin/src/device_financier/financier_be.sh"

	for _,v:=range args{
		command = command + " " + v
		fmt.Println("command is ",command)
    }

	fmt.Println("final command is ",command)
	cmd:=exec.Command("sh", "-c", command)

	var out bytes.Buffer
	var error bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &error
	if err:=cmd.Run();err!=nil{
	fmt.Println("Start Script failed:", err)
	w.Write([]byte (error.String()))
}
	fmt.Println("Execute finished:" ,out.String())
	w.Write([]byte(out.String()))
	//return out.String()
}

