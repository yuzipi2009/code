
package main

// this version added silence install part
// this version added restart layer function
// 2020.1.17, this version added the hashkey
// 2020.1.17, add return code for each condition
import (
	"bytes"
	"encoding/json"
	"encoding/csv"
	"fmt"
	"io/ioutil"
	"log"
	"github.com/gorilla/mux"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"./db"
)

type VersionWrapper struct {
	Data []Version `json:"data"`
}

type Response struct {
	Status string
	StatusCode int
}

type Version struct {
	Date    string  `json: "Date"`
	Service string `json:"Service"`
	New_Version string `json:"New_Version"`
	Comment string `json:"Comment"`
	Executor string `json:"Executor"`
}

var CONFIG_FILE_NAME string

func homepage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to the HomePage!")
	fmt.Println("Endpoint Hit: homePage")
}


func handleRequests(){

	//below is for mux
	myRouter := mux.NewRouter().StrictSlash(true)
	myRouter.HandleFunc("/",homepage)
	myRouter.HandleFunc("/all",returnAllRecord)
	myRouter.HandleFunc("/test",createNewRecord).Methods("POST")
	myRouter.HandleFunc("/stage",createNewRecord).Methods("POST")
	myRouter.HandleFunc("/recomendation",portaltool).Methods("POST")
	myRouter.HandleFunc("/status",portaltool).Methods("POST")
	myRouter.HandleFunc("/uploader",portaltool).Methods("POST")
	myRouter.HandleFunc("/silent",portaltool).Methods("POST")
	myRouter.HandleFunc("/bugid",InputBugId).Methods("POST")
	myRouter.HandleFunc("/gettime",GetTime).Methods("GET")
	myRouter.HandleFunc("/restart",portaltool).Methods("POST")
	myRouter.HandleFunc("/hashkey",HashKey).Methods("GET")
	myRouter.HandleFunc("/DeviceFinancier",portaltool).Methods("POST")
	log.Fatal(http.ListenAndServe(":6000", myRouter))

}

func returnAllRecord (w http.ResponseWriter, r *http.Request){
	fmt.Println("Endpoint Hit: returnAllRecord")
	json.NewEncoder(w).Encode(Content)
}


func createNewRecord(w http.ResponseWriter, r *http.Request) {

	//Judge the host Url, it can be test.kaiostech.com or stage.kaiostech.com
	path:= r.RequestURI
	env:= strings.Trim(path,"/")
	fmt.Println("env is ", env)
	switch env {
	case "test":
		CONFIG_FILE_NAME="/data/tools/repository/nginx/html/app/static/kaios_app/datatables/deploy/test.json"
	case "stage":
		CONFIG_FILE_NAME="/data/tools/repository/nginx/html/app/static/kaios_app/datatables/deploy/stage.json"
	}

	fmt.Println("file is", CONFIG_FILE_NAME)

	// Read the file, and Unmarsh it to &Content
	var Body,_= ioutil.ReadFile(CONFIG_FILE_NAME)
	_= json.Unmarshal(Body, &Content)

	// Post action
	//fmt.Println("Endpoint Hit: Post ")
	reqBody, _ := ioutil.ReadAll(r.Body)
	fmt.Println("body is ",string(reqBody))
	var new_version Version
	//fmt.Println("content is :",Content)
	err:=json.Unmarshal(reqBody, &new_version)
	if err != nil{
		fmt.Fprintf(w,"Unmarshal Failed:  %+v",err)
	}
	fmt.Printf("New version is:\n %+v", new_version)
	//If someone Post the same version multiple times, we need to uniq it and keep the lates        //t one and delete the old one


	var ContentTemp  []Version
	fmt.Println("the length of Content is :", len(Content["data"]))
	for k,v := range Content["data"]{

		// if found the same version with the same excutor, then ignore it.
		if v.New_Version == new_version.New_Version && v.Executor == new_version.Executor{
			fmt.Printf("Found same version with same executor, key is %s, value is %s",k,v)

		}else{
			//Only keep the uniq one
			ContentTemp = append(ContentTemp,Content["data"][k])
		}

	}

	//append the new version
	Content["data"] = append(ContentTemp,new_version)
	fmt.Println(Content)


	a:=WriteFile(CONFIG_FILE_NAME, Content)
	fmt.Fprintf(w,"\n%+v\n",a)
	fmt.Fprintf(w,"%+v\n",new_version)
}

func InputBugId(w http.ResponseWriter, r *http.Request) {
	// Parse Form and Get value from ajax
	r.ParseForm()
	fmt.Println(r.Form)
	bug_id := r.FormValue("bug_id")
	id := r.FormValue("id")
	env := r.FormValue("env")
	fmt.Println("id , env is ",id,env)
	//^^^^^^^^^^^^ Update the bug_id into Cassandra ^^^^^^^^
	//Session := cassandra.Session
	cassandra.AttachBugId(bug_id,id,env)
	//defer Session.Close()
	//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
}

func GetTime(w http.ResponseWriter, r *http.Request){
	file:="/data/bin/src/exception/time.txt"
	if fo,err:=os.Open(file);err == nil {
		defer fo.Close()
		if contents,err:=ioutil.ReadAll(fo);err == nil {
			result:=strings.Replace(string(contents),"\n","",-1)
			data:=fmt.Sprintf("Last run at: %s",result)
			w.Write([]byte(data))
		}
	}

}


// This function for "RandApp"
func portaltool(w http.ResponseWriter, r *http.Request) {
	// Parse Form and Get value from ajax

	r.ParseForm()
	fmt.Println(r.Form)
	fmt.Println("index_code is ",r.FormValue("index_code"))
	app_code := r.FormValue("app_code")
	//index_code := r.FormValue("index_code")
	env := r.FormValue("env")
	p:=r.RequestURI
	path:=strings.Trim(p,"/")

	var command string
	switch path {
	case "recomendation":
		index_code := r.FormValue("index_code")
		command = fmt.Sprintf("./rank_app.sh  %s %s %s", env, app_code,index_code)
	case "status":
		command = fmt.Sprintf("./get_index.sh  %s %s", env, app_code)
	case "uploader":
		app_name := r.FormValue("app_name")
		command = fmt.Sprintf("./search_uploader.sh  %s", app_name)
	case "silent":
		tf := r.FormValue("tf")
		command = fmt.Sprintf("./set_silent.sh  %s %s %s", env,app_code,tf)

	case "restart":
		layer := r.FormValue("layer")
		command = fmt.Sprintf("./restart_cloud.sh  %s %s", env,layer)

	case "DeviceFinancier":
		msg :=  r.FormValue("msg")
		imeis := r.FormValue("imeis")
		action := r.FormValue("action")


		if (strings.Index(imeis, " ") != -1){
			fmt.Fprintf(w, "[Error] Imeis must split by comma -> aaa,bbb,ccc")
			return
		}

		// Gen the imei json file
		type Message struct {
			M string `json:"m"`
		}
		type Data struct {
			Args Message `json:"args"`
			Imeis []string `json:"imeis"`
		}

		var imeifile = "/data/bin/hawk/jwt/imei.json"
		var message Message
		var data Data
		message.M=msg
		data.Imeis=strings.Split(imeis,",")
		data.Args=message

		if jsondata,err:=json.MarshalIndent(data,"", " ");err != nil {
			fmt.Fprintf(w,"Marshal Json failed %+v\n",err)
		}else {
			//fmt.Fprintf(w, "%+v", jsondata)

			fo, err := os.OpenFile(imeifile, os.O_TRUNC|os.O_WRONLY, 0666)

			if err != nil {
				fmt.Println("Open Source file Error", err)
			}

			defer fo.Close()

			if _, err := fo.Write(jsondata);err != nil{
				fmt.Fprintf(w,"Write Json failed %+v\n",err)
			}
		}

		command = fmt.Sprintf("./device_financier.sh %s %s", imeifile,action)
	}

	fmt.Println("command is ",command)
	cmd:=exec.Command("/bin/bash", "-c", command )

	var out bytes.Buffer
	var error bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &error
	if err:=cmd.Run();err!=nil{
		fmt.Println("Start Script failed:", error.String())
		w.Write([]byte(error.String()))
		//return
	}

	fmt.Println("Execute finished:" ,out.String())
	w.Write([]byte(out.String()))
}

// ioutil.WriteFile requires the data must be []byte type, so use Marshal to convert it
func WriteFile (file string,version map[string][]Version) (resp Response) {
	//data:=[]byte(version)
	data,_:=json.Marshal(version)

	fo,err2:=os.OpenFile(CONFIG_FILE_NAME, os.O_TRUNC|os.O_WRONLY, 0111)

	if err2 != nil{
		fmt.Println("Open Source file Error",err2)
	}

	defer fo.Close()

	_,err:=fo.Write(data)
	if err == nil {
		resp = Response{
			Status:"POST OK",
			StatusCode: 200,
		}
	}else{
		resp = Response{
			Status:"POST Failed",
			StatusCode:400,
		}
		fmt.Println("Write Data Error",err)
	}

	return

}
func ConJson (data interface{}, writer http.ResponseWriter) {
	if json,err:=json.MarshalIndent(data, "", " ");err == nil{
		fmt.Fprintf(writer,"%+v",string(json))

	}else {
		fmt.Fprintf(writer,"Failed generate json %v+",data,err)
	}

}
// This function is to get the hashkey json
func HashKey (w http.ResponseWriter, r *http.Request) {

	r.ParseForm()
	fmt.Println(r.Form)
	type Service struct {
		OEM string  `json:"oem"`
		Type string `json:"type"`
		KeyId string `json:"key_id"`
		Key string `json:"key"`
	}
	type FullData struct {
		Code int `json:"code"`
		Data []Service 	`json:"data"`
	}

	type ErrorData struct {
		Code int        `json:"code"`
		Error string	`json:"error"`
	}

	var service  Service
	var temp []Service
	var fulldata FullData
	var errordata ErrorData

	file := "/tmp/encrypt_key.csv"
	// If file not exsit, print error
	if _,err:=os.Stat(file);err !=nil{
		errordata.Code=404
		errordata.Error="csv file not exsit."
		ConJson(errordata,w)
		return
	}

	if csvfile,err := os.Open(file); err == nil {
		defer csvfile.Close()
		reader := csv.NewReader(csvfile)
		reader.FieldsPerRecord = 0
		if csvdata, err2 := reader.ReadAll(); err2 == nil {
			for _,v:=range (csvdata){
				service.OEM=v[0]
				service.Type=v[1]
				service.KeyId=v[2]
				service.Key=v[3]
				temp= append(temp, service)

			}
			fulldata.Data=temp
			fulldata.Code=200
			// if everything goes well, print the final json body
			ConJson(fulldata,w)

		}else {
			errordata.Code=503
			errordata.Error="Read csvfile failed."
			ConJson(errordata,w)
			return
		}
	} else {
		errordata.Code=503
		errordata.Error="Open csvfile failed."
		ConJson(errordata,w)
		return
	}


}

//////////////////////Main///////////////////////

var Content map[string][]Version

func main () {
	handleRequests()
}