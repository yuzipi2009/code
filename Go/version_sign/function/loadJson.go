package function

import (
"encoding/json"
"log"
"io/ioutil"
)
type PackageInfo struct {
	PId string `json:"pid"`
	Md5  string `json:"md5"`
	//FileName string `json:"file_name"`
}

//The path of jsonfile as parameter
//Return a json data of type Info

func LoadJson (path string) PackageInfo{
	var Info PackageInfo
	fd,err:=ioutil.ReadFile(path)
	if err != nil {
		log.Printf("Load_Json:Open source error:%s, file_path is %s",err,path)
	}

	err2:=json.Unmarshal(fd, &Info)
	if err != nil {
		log.Println("Load_Json:Unmarshal error",err2)
	}

	return Info

}