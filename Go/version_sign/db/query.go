package db

import (
	"database/sql"
	"log"
)

type  Customer struct {
		Pid string
		ProjectName string
		OdmName string
	}


type Location struct {
	Root_key string `json:"root_key"`
	Image_key string `json:"image_key"`
	Image_presign_path string `json:"image_pre_sign"`
	Image_signed_path string  `json:"image_signed"`
	Da_image_path string `json:"da_image_path"`

}
var customer = new(Customer)
var location = new(Location)

func Query_Project_Odm_In_Eproject(pid string) (projectName,odmName string,err error) {

	row := ProjectsHandler.QueryRow("select p.name as projectName,c.name as odmName from projects as p " +
		"left join customers as c on p.odm_id = c.id where p.id = ?",pid)
	err =row.Scan(&customer.ProjectName,&customer.OdmName)
	if err == sql.ErrNoRows{
		//log.Println("No result found")
		return customer.ProjectName, customer.OdmName, err
	}else if err != nil {
			log.Printf("Query_Project_Odm_In_Eproject, err:%v", err)
			return customer.ProjectName, customer.OdmName, err
	}

	log.Printf("project is %s, customer is %s",customer.ProjectName,customer.OdmName)
	//j,_:=json.Marshal(customer)
	//log.Println("j is ",string(j))
	return customer.ProjectName,customer.OdmName,err
}


func Query_Project_Odm_In_Signature(pid string) (pid2,odmName string,err error) {

	row := SignatureHandler.QueryRow("select pid,odm_name from secret where pid=?",pid)
	err = row.Scan(&customer.Pid,&customer.OdmName)
	if err == sql.ErrNoRows{
		//log.Println("No result found")
		return customer.Pid, customer.OdmName, err
	} else if err != nil{
		log.Printf("Query_Project_Odm_In_Signature failed, err:%v",err)
		return customer.Pid, customer.OdmName, err
	}
	log.Println(customer.Pid,customer.OdmName)
	//j,_:=json.Marshal(customer)
	//log.Println("j is ",string(j))
	return customer.Pid,customer.OdmName, err
}

func Query_Location_In_Signature(pid string) (rootKey,imageKey string,err error) {

	row := SignatureHandler.QueryRow("select rootKey,imageKey from prvk_location where pid=?",pid)
	err = row.Scan(&location.Root_key,&location.Image_key)
	if err == sql.ErrNoRows{
		//log.Println("No result found")
		return location.Root_key,location.Image_key, err
	} else if err != nil{
		log.Printf("scan eproject failed, err:%v",err)
		return location.Root_key,location.Image_key, err
	}
	log.Println("location is ",location.Root_key,location.Image_key)
	//j,_:=json.Marshal(customer)
	//log.Println("j is ",string(j))
	return location.Root_key,location.Image_key, err
}


func QueryAccount(hashName string) (hashPw string, err error){

	type  User struct {
		HashName int `json:"hash_name"`
		HashPw string `json:"hash_pw"`
	}
	//user := new(User)
	row := SignatureHandler.QueryRow("select pwd from customers where name=?",hashName)
	err =row.Scan(hashPw)
	return

	}
