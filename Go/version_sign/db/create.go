package db

import (
	"fmt"
	"log"
)

func InsertKey(pid string ,prvk64,pname,odmName string) error{
	//salt:=initiation.C.Db["salt"]

	encode64:= Encode(prvk64)
	fmt.Println("prvk is ",prvk64)
	ret,err := SignatureHandler.Exec("insert INTO secret(pid,project_name,odm_name,prvk) values(?,?,?,?)",pid,pname,odmName,encode64)

    if err != nil{
    	return err
	}

	lastInsertID,_ := ret.LastInsertId()

	//number of rows affected
	rowsaffected,_ := ret.RowsAffected()
	log.Printf("LastInsertID: %d, RowsAffected:%d",lastInsertID,rowsaffected)

	return nil
}

func Insert_Sign_History(pid string ,pname string, odm_name string,signed bool) error{

	ret,err := SignatureHandler.Exec("insert INTO sign_history(pid,project_name,odm_name,signed) values(?,?,?,?)",pid,pname,odm_name,true)
    if err != nil{
    	return err
	}

	lastInsertID,_ := ret.LastInsertId()
	log.Println("LastInsertID:",lastInsertID)

	//how many line affected
	rowsaffected,_ := ret.RowsAffected()
	log.Println("RowsAffected:",rowsaffected)

	return nil
}

func Insert_Location_In_Signature(pid string,rootKey,imageKey string)(err error) {

	row := SignatureHandler.QueryRow("insert into prvk_location(pid,rootKey,imageKey) values(?,?,?)",pid,rootKey,imageKey)
	err = row.Scan(&location.Root_key,&location.Image_key)
	if err != nil{
		log.Println(location.Root_key,location.Image_key)
		return nil
	}
	fmt.Println("Insert path is ",rootKey)
		return err

}