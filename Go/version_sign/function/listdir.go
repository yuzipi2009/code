package function

import (
	"fmt"
	"io/ioutil"
	"log"
	"strings"
)

//fileMap is map
// {package:xxxxx,json:info.json}
func Listdir (dirname string) (fileMap map[string]string){

	fileMap=make(map[string]string,0)

	fileInfos,err:=ioutil.ReadDir(dirname)
	if err != nil{
		log.Fatal(err)
	}

	for _,fi := range fileInfos{
		// normally there is only one dir -> "download", so ignore it
		// filename should end with "json"
		// if it is dir or end with zip(the source zip file), continue.
		if fi.IsDir() || strings.HasSuffix(fi.Name(),"zip") {
			continue
		}
		filename:=dirname  + "/" +fi.Name()
		//fmt.Printf("dirname is %s,file_name is %s",dirname,fi.Name())
		if strings.HasSuffix(filename,"json"){
			fileMap["json"]=filename
		}
	}
	fmt.Println("filemap is ",fileMap)
	return fileMap
}
