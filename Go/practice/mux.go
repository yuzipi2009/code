package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
)

//package main

import (
"encoding/json"
"fmt"
"log"
"net/http"
)




type Article struct {
	TiTle string `json:"Title"`
	Desc string `json:"desc"`
	Content string `json:"content"`
}



func homepage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Welcome to the HomePage!")
	fmt.Println("Endpoint Hit: homePage")
}

func handleRequests(){
	//fmt.Println(News)
	http.HandleFunc("/", homepage)
	http.HandleFunc("/record", returnAllRecord)
	log.Fatal(http.ListenAndServe(":1000", nil))

}

func returnAllRecord (w http.ResponseWriter, r *http.Request){
	fmt.Println("Endpoint Hit: returnAllRecord")
	fmt.Println(r)
	fmt.Println(w)

	json.NewEncoder(w).Encode(News)
}

var News [] Article = [] Article{
	{TiTle:"news1", Desc:"Description1", Content:"Content1"},
	{TiTle:"news2", Desc:"Description2", Content:"Content2"},
}

func main_2 () {
	//var News []Article
	fmt.Println(News)
	handleRequests()

}