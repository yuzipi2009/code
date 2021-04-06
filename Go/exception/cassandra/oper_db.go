package cassandra

import (
	log "code.google.com/p/log4go"
	"empowerthings.com/cumulis/utils/uuid"
	"encoding/json"
	"fmt"
	"os"
)

type ajax struct {
	ID string `json:"ID"`
	Bug_Id string `json:"Bug_ID"`
	Created_at string `json:"Created_at"`
	Version string `json: "Version"`
	Exception string `json:"Exception"`
	Env string `json:"Env"`
	Host string `json:"Host"`
}

type Response struct {
	Status string
	StatusCode int
}


// ioutil.WriteFile requires the data must be []byte type, so use Marshal to convert it
func WriteFile (jsonfile string,version map[string][]ajax) {
	//data:=[]byte(version)
	data,_:=json.Marshal(version)

	fo,err2:=os.OpenFile(jsonfile, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0666)

	if err2 != nil{
		log.Error("Open Source file Error",err2)
	}

	defer fo.Close()

	_,err:=fo.Write(data)
	if err != nil {
		log.Error("Write exception_env.json failed",err)
	}
}

// this func is to save the exception into kaios_sh.exception table
func InserException (table,date,version,exception,env,host string){
	var gocqluuid string
	var errs []string
	if len(errs) == 0 {
		fmt.Println("Saving a record")
		// generate a unique UUUID for one record
		gocqluuid = uuid.NewUuid()
		// write data to cassandra
		cql:= fmt.Sprintf("INSERT INTO kaios_sh.%s (id,version,created_at,exception,env,host) VALUES (?,?,?,?,?,?)",table)
		if err := Session.Query(cql,gocqluuid,version,date,exception,env,host).Exec();err != nil {
			//errs=append(errs,string(err))
			log.Error("Insert Error:",err)
		} else {
			//created = true
			log.Info("INSERT INTO kaios_sh.exception -> %s,%s,%s,%s,%s,%s",gocqluuid,date,version,exception,env,host)
		}
	}
}

// this func is to save the exception into kaios_sh.exception table
func UpdateBugId (ch chan string,bug_id,id string){
	fmt.Println("start")
	var errs []string
	if len(errs) == 0 {
		// update bugId to cassandra
		if err := Session.Query("UPDATE kaios_sh.exception set bug_id= ? where id=?",bug_id,id).Exec();err != nil {
			//errs=append(errs,string(err))
			fmt.Println("Update Bug_ID Error:",err)
		} else {
			//created = true
			fmt.Println("Update Bug_ID -> %s,%s",bug_id,id)
		}
	}
	// after update bug_id, need to gen the json again to let the portal get latest data
	ch <- "Trigger genjson go routine"
	fmt.Println("Generated json")
}

func GenJson (ch chan string) {
	for {
		<-ch
		var t ajax
		// just define a slice here
		var ts []ajax
		fmt.Println("Start GEN JSON..................")
		AjaxJson := map[string][]ajax{}
		envlist := []string{"test", "stage"}
		for _, e := range envlist {
			// assgin an empty slice for each loop
			ts = make ([]ajax,0)
			iter := Session.Query("SELECT * FROM kaios_sh.exception WHERE env = ? ALLOW FILTERING", e).Iter()
			for iter.Scan(&t.ID, &t.Bug_Id, &t.Created_at, &t.Env, &t.Exception, &t.Host, &t.Version) {
				//       fmt.Println("Start loop: ")
				//	fmt.Println("id and  env: ",t.ID,t.Env)
				//fmt.Println("bug_id is ",t.Bug_Id)
				//fmt.Println("created_at is ",t.Created_at)
				//fmt.Println("env is ",t.Env)
				//fmt.Println("exception is ",t.Exception)
				//fmt.Println("host is ",t.Host)
				// ts is a silce of type ajax, the item of the silce is t.
				ts = append(ts, t)

				//fmt.Printf("loopenv is %s, cassaenv is %s\n",e,t.Env)
				// fmt.Println("ajax is",t)

			}
			// k is "data", v is ts
			AjaxJson["data"] = ts
			JsonFile := fmt.Sprintf("./json/exception_%s.json", e)
			//fmt.Printf("Json file is %s, ID is %s \n",JsonFile,)
			WriteFile(JsonFile, AjaxJson)
			//fmt.Println("Write to:",JsonFile)
			//fmt.Println("End loop! \n\n\n")
		}
	}
}

func CheckRecod (date,env,host string) (count int){
	iter := Session.Query("SELECT count(*) FROM kaios_sh.exception WHERE created_at = ? and env = ? and host =? ALLOW FILTERING", date,env,host).Iter()
	for iter.Scan(&count) {

	}
	return
}