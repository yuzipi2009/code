
package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io/ioutil"
	"log"
	"net/http"
)

type Article struct {
Id    string  `json: "ID"`
TiTle string `json:"Title"`
Desc string `json:"Desc"`
Content string `json:"Content"`
}



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
myRouter.HandleFunc("/all/{id}",returnSingleKey)
myRouter.HandleFunc("/add",createNewRecord).Methods("POST")
myRouter.HandleFunc("/delete/{id}",DeleteRecord).Methods("DELETE")
myRouter.HandleFunc("/update/{id}",UpdateRecord).Methods("PUT")
log.Fatal(http.ListenAndServe(":1000", myRouter))
}

func returnAllRecord (w http.ResponseWriter, r *http.Request){
fmt.Println("Endpoint Hit: returnAllRecord")
fmt.Println(r)
//fmt.Println(News)

json.NewEncoder(w).Encode(News)
}

func returnSingleKey (w http.ResponseWriter, r *http.Request){
	vars := mux.Vars(r)
	key := vars["id"]

    for _, item := range News {
    	if item.Id == key {
			json.NewEncoder(w).Encode(item)
		}
	}
	//fmt.Fprintf(w, "Key: " + key)  //print on the screen
}

func createNewRecord(w http.ResponseWriter, r *http.Request)  {
	// Post
	fmt.Println("Endpoint Hit: Post ")
	reqBody, _ := ioutil.ReadAll(r.Body)
	var new_line Article
	json.Unmarshal(reqBody, &new_line)
	News = append(News,new_line)
	json.NewEncoder(w).Encode(News)
	fmt.Fprintf(w, "%+v", string(reqBody))

}

func DeleteRecord(w http.ResponseWriter, r *http.Request)  {
	fmt.Println("Endpoint Hit: DELETE ")
	vars := mux.Vars(r)

	id := vars["id"]

	for index, line := range News {
		if line.Id ==id {
			News = append(News[:index], News[index+1:]...)
			News = append(News)
		}
	}

}

func UpdateRecord(w http.ResponseWriter, r *http.Request)  {
	fmt.Println("Endpoint Hit: PUT ")
	reqBody, _ := ioutil.ReadAll(r.Body)
	var new_line Article
	json.Unmarshal(reqBody, &new_line)

	vars := mux.Vars(r)

 	id := vars["id"]

	for index, line := range News {
		if line.Id ==id {
			News = append(News[:index], News[index+1:]...)
			News = append(News, new_line)
			json.NewEncoder(w).Encode(News)
		}
	}

}

//var News [] Article = [] Article{
//	{TiTle:"news1", Desc:"Description1", Content:"Content1"},
//	{TiTle:"news2", Desc:"Description2", Content:"Content2"},
//}

var News [] Article

func main_temp () {
	News = [] Article {
		{Id:"1",TiTle:"news1", Desc:"Description1", Content:"Content1"},
		{Id:"2",TiTle:"news2", Desc:"Description2", Content:"Content2"},
	}
	//var News []Article
	//fmt.Println(News[0].Id)
	handleRequests()

}
