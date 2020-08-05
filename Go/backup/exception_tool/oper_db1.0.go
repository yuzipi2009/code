
package cassandra

import (
	log "code.google.com/p/log4go"
	"empowerthings.com/cumulis/utils/uuid"
	"fmt"
	"reflect"
)

type ajax struct {
	ID string `json:"id"`
	Bug_Id int `json:"bug_id"`
	Created_at string `json:"created_at"`
	Env string `json:"env"`
	Exception string `json:"exception"`
	Host string `json:"host"`
}

type ajax2 struct{
	data []ajax
}

// this func is to save the exception into kaios_sh.exception table
func InserException (table,date,exception,env,host string){
	var gocqluuid string
	var errs []string
	//var created bool =false
	if len(errs) == 0 {
		fmt.Println("Saving a record")
		// generate a unique UUUID for one record
		gocqluuid = uuid.NewUuid()
		// write data to cassandra
		cql:= fmt.Sprintf("INSERT INTO kaios_sh.%s (id,created_at,exception,env,host) VALUES (?,?,?,?,?)",table)
		if err := Session.Query(cql,gocqluuid,date,exception,env,host).Exec();err != nil {
			//errs=append(errs,string(err))
			log.Error("Insert Error:",err)
		} else {
			//created = true
			log.Info("INSERT INTO kaios_sh.exception -> %s,%s,%s,%s,%s ",gocqluuid,date,exception,env,host)
		}
		//if created{
		//	fmt.Println("user_id",gocqluuid)
		//	json.NewEncoder(w).Encode(NewRecordID{ID:gocqluuid})
		//}	else{
		//	fmt.Println("errors",errs)
		//	json.NewEncoder(w).Encode(ErrorResponse{Errors:errs})
		//}
	}
}

func Select (table string) {
	//var datajson []*ajax
	//var id string
	var t ajax
	var t2 []ajax
	t3:= map[string][]ajax  {}
	stage:="test"
	//var	tbug_id int
	//stmt:= fmt.Sprintf("SELECT id FROM kaios_sh.exception WHERE env = ?",stage)")
	iter := Session.Query("SELECT * FROM kaios_sh.exception WHERE env = ? ALLOW FILTERING",stage).Iter()
	for iter.Scan(&t.ID,&t.Bug_Id,&t.Created_at,&t.Env,&t.Exception,&t.Host){
		fmt.Println("id is ",t.ID)
		fmt.Println("bug_id is ",t.Bug_Id)
		fmt.Println("created_at is ",t.Created_at)
		fmt.Println("env is ",t.Env)
		//fmt.Println("exception is ",t.Exception)
		fmt.Println("host is ",t.Host)
		t2 = append(t2,t)
		//; err != nil {
		//if err != gocql.ErrNotFound {
		//	fmt.Println("Query failed: %v", err)
	}

	fmt.Println("t2 is ",reflect.TypeOf(t2))
	t3["data"]=t2
	//err:=json.Unmarshal(t3,&t2 )
	fmt.Printf("f3 is %+v",t3)
}
//fmt.Println("iter dis ", *iter)

//fmt.Printf("newiteam is %v+", newitem)
//stmt, names := qb.Select(table).ToCql()
//fmt.Printf("stmt is %s, name is %s\n", stmt, names)
//err := gocqlx.Select(&datajson, Session.Query(stmt))
//fmt.Println("error is ", err)
//q := gocqlx.Query(Session.Query(stmt), names).BindStruct(qb.M{
//	"env": "stage",


//if err := q.GetRelease(&ajson); err != nil {
//	fmt.Println("error",err)
//}else {
//	fmt.Println("ajason is ",ajson)

// stdout: {Patricia Citizen [patricia.citzen@gocqlx_test.com patricia1.