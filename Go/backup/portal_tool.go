package config

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"github.com/gorilla/mux"
	"net/http"
	"os"
	"os/exec"
	"strings"
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
	Change string `json:"Change"`
}

var logname string = "./display_portal.log"
var CONFIG_FILE_NAME string

func homepage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to the HomePage!")
	fmt.Println("Endpoint Hit: homePage")
	// write to log
	a:=123
	print_log(a)
}

func print_log(data interface{}) {
	f, err := os.OpenFile(logname, os.O_CREATE|os.O_RDWR|os.O_APPEND, 0666)
	if err != nil {
		fmt.Println("[Eror] can't find the log file")
	}
	log.SetOutput(f)
	fmt.Println("aaaaaaaaa")
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	log.Println(data)
	fmt.Println("bbbbbbbbbb")
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
	myRouter.HandleFunc("/temp",portaltool).Methods("POST")
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
		if v.New_Version != new_version.New_Version{
			//Only keep the uniq one
			ContentTemp = append(ContentTemp,Content["data"][k])

		}else{
			fmt.Println(k,v)
		}

	}

	//append the new version
	Content["data"] = append(ContentTemp,new_version)
	fmt.Println(Content)


	a:=WriteFile(CONFIG_FILE_NAME, Content)
	fmt.Fprintf(w,"\n%+v\n",a)
	fmt.Fprintf(w,"%+v\n",new_version)

	// write to log
	print_log(new_version)
}

// This function for "RandApp"
func portaltool(w http.ResponseWriter, r *http.Request) {
	// Parse Form and Get value from ajax

	r.ParseForm()
	fmt.Println(r.Form)
	fmt.Println(r.Header)
	fmt.Println("index_code is ",r.FormValue("index_code"))
	app_code := r.FormValue("app_code")
	//index_code := r.FormValue("index_code")
	env := r.FormValue("env")
	//command := fmt.Sprintf("/data/bin/display_tool/rank_app.sh  %s %s %s", env, app_code,index_code)
	p:=r.RequestURI
	path:=strings.Trim(p,"/")

	var command string
	switch path {
	case "recomendation":
		index_code := r.FormValue("index_code")
		command = fmt.Sprintf("/data/bin/display_tool/rank_app.sh  %s %s %s", env, app_code,index_code)
	case "status":
		command = fmt.Sprintf("/data/bin/display_tool/get_index.sh  %s %s", env, app_code)
	case "uploader":
		app_name := r.FormValue("app_name")
		command = fmt.Sprintf("/data/bin/display_tool/search_uploader.sh  %s", app_name)
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

	//write to the log
	print_log([]byte(out.String()))
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

//////////////////////Main///////////////////////

var Content map[string][]Version

func main () {
	handleRequests()
}
