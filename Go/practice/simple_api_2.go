
package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io/ioutil"
	"log"
	"net/http"
	"os"
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

const CONFIG_FILE_NAME = "/home/yuxiao/Desktop/my_golang/prod.json"

func homepage(w http.ResponseWriter, r *http.Request) {
fmt.Fprintf(w, "Welcome to the HomePage!")
fmt.Println("Endpoint Hit: homePage")
}


func handleRequests(){
//fmt.Println(News)
//http.HandleFunc("/", homepage)
//http.HandleFunc("/record", returnAllRecord)


//below is for mux
//create a new instance of a mux router
//fmt.Println(News)
myRouter := mux.NewRouter().StrictSlash(true)
myRouter.HandleFunc("/",homepage)
myRouter.HandleFunc("/all",returnAllRecord)
//myRouter.HandleFunc("/all/{id}",returnSingleKey)
myRouter.HandleFunc("/add",createNewRecord).Methods("POST")
//myRouter.HandleFunc("/delete/{id}",DeleteRecord).Methods("DELETE")
//myRouter.HandleFunc("/update/{id}",UpdateRecord).Methods("PUT")
log.Fatal(http.ListenAndServe(":1000", myRouter))

}

func returnAllRecord (w http.ResponseWriter, r *http.Request){
fmt.Println("Endpoint Hit: returnAllRecord")
fmt.Println(r)
fmt.Println(w)
//foo, _:=json.MarshalIndent(Content, " ", "	")
//fmt.Println("aaaa", r)
//Content_s:=make([]Version,0)
//Content_2:=append()
//a1:=Content[len(Content)-1]
json.NewEncoder(w).Encode(Content)
//fmt.Println("bbb",w)


}

//func returnSingleKey (w http.ResponseWriter, r *http.Request){
//	vars := mux.Vars(r)
//	key := vars["New_Version"]
//
 //   for _, item := range content {
   // 	if item.New_Version== key {
	//		json.NewEncoder(w).Encode(item)
	//	}
	//}
	//fmt.Fprintf(w, "Key: " + key)  //print on the screen
//}

func createNewRecord(w http.ResponseWriter, r *http.Request) {

	// Post
	fmt.Println("Endpoint Hit: Post ")
	reqBody, _ := ioutil.ReadAll(r.Body)
	//fmt.Println("reqBody is :",reqBody)

	var new_version Version
	fmt.Println("content is :",Content)
	err:=json.Unmarshal(reqBody, &new_version)
	if err != nil{
		fmt.Fprintf(w,"%+v","Unmarshal Error:\n", err)
	}
	fmt.Println("new is :",new_version)
	Content["data"] = append(Content["data"],new_version)
	//json.NewEncoder(w).Encode(new_version)
	//fmt.Fprintf(w, "%+v", Content["data"][len(Content["data"])-1])
	a:=WriteFile(CONFIG_FILE_NAME, Content)
	fmt.Fprintf(w,"\n%+v\n",a)
}

// ioutil.WriteFile requires the data must be []byte type, so use Marshal to convert it
func WriteFile (file string,version map[string][]Version) (resp Response) {
	//data:=[]byte(version)
	data,_:=json.Marshal(version)
	fo,_:=os.OpenFile(CONFIG_FILE_NAME, os.O_TRUNC|os.O_WRONLY, 0644)
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
	}

	return


	//fmt.Println("result:",n,err)



	//err:= ioutil.WriteFile(file,data,0644)
	//if err == nil{
	//	fmt.Println("Post Success")
	//} else {
	//	fmt.Println("POST Failed",err)
	//}
}

//Content, = ioutil.ReadFile(file)
//var err string

var Body,_= ioutil.ReadFile(CONFIG_FILE_NAME)
//var Content  VersionWrapper
var Content map[string][]Version
//var test string = "abc"
func main () {
	//body,_:= ioutil.ReadFile(CONFIG_FILE_NAME)

    //fmt.Printf("%+v\n",body)
    //a1:=a
    //fmt.Println(a1)
    //_=json.Unmarshal(Body,&Content)
    //fmt.Printf("%+v",Content["Data"])
	//a:=make(map[string][]Version)
    _= json.Unmarshal(Body, &Content)

    //fmt.Printf("%+v",Content["data"][2])
    //a1:= Content[1:2]

    //fmt.Printf("%+v\n", a1)


    //if err != nil {
    	//panic(err)
	//}
    //fmt.Println(reflect.TypeOf(Content))
    //Content = string(body)
    //Content:=string(body)
    //fmt.Println("1",content_4)
    //content_2:=make([]string,0)
    //content_3:=append(content_2,Content)
    //fmt.Println("2",Content)

    //fmt.Println(reflect.TypeOf(body))
    //fmt.Println(Content)
	handleRequests()

}
