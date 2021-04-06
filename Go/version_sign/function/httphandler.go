package function

import (
	"database/sql"
	"fmt"
	"github.com/gorilla/mux"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path"
	"strings"
	"time"
	"version_sign/db"
)

type reponsejson struct {
	Code int `json:"code"`
	Message string `json:"message"`
}

var r reponsejson

// instance for sftp methods
var p = Project{}
var f Fs = p

func HandleRequests(){

	//below is for mux
	myRouter := mux.NewRouter().StrictSlash(true)
	myRouter.HandleFunc("/sign",Signature).Methods("POST")
	myRouter.HandleFunc("/key",GenKey).Methods("POST")
	log.Fatal(http.ListenAndServe(":6000", myRouter))

}

//this function is to create keys
func GenKey (w http.ResponseWriter, r *http.Request) {

	log.Println("hit Genkey")
	//** step1:get the projectname and odmname from eproject DB

	pid:= r.FormValue("pid")
	platform := r.FormValue("platform")
	//log.Println("pid is ",pid)
	pname,odmName,queryEprojectErr:=db.Query_Project_Odm_In_Eproject(pid)
	if queryEprojectErr != nil{
		resp:=fmt.Sprintf("Didn't find record from eproject",queryEprojectErr)
		log.Println(resp)
		w.Write([]byte(resp))
		return
	}else{
		log.Printf("(1/5)Found pname=%s, odmName=%s in Eproject",pname,odmName)
	}

	pname=strings.Replace(pname," ","_",-1)
	odmName=strings.Replace(odmName," ","_",-1)

	start:=fmt.Sprintf("\n=====Start Gen_key for %s-%s=====\n",odmName,pname)
	w.Write([]byte(start))

	//** step2: get the projectname and odmaname from signature DB
	//query the pid in the signature DB, compare pname and pname2, odmName and odmName2, ensure it doesn't have rerecord.

	w.Write([]byte("STEP 1: Query DB"))
    pname2,odmName2,querySignErr:=db.Query_Project_Odm_In_Signature(pid)
    if querySignErr == sql.ErrNoRows {
		log.Printf("(2/5)The peoject=%s,odm=%s is not signed before", pname, odmName)
	}else if querySignErr == nil{
    	log.Printf("Conflict Record, Found pname=%s,odmname=%s in DB_Signature",pname2,odmName2)
		w.Write([]byte(".....Failed: Conflict Record\n"))
    	return
	} else {
		log.Println("db.Query_Project_Odm_In_Signature error",querySignErr)
		return
	}
	w.Write([]byte(".....OK\n"))

    //step3: runbash, save keys to $outPath
	w.Write([]byte("STEP 2: Generate Key"))

    //The keys will be saved into outPATH/pname, and it will be created by
    //only "basePath" should be created by golang


    basePath:= fmt.Sprintf("/data/var/keys/%s",odmName)
	outPath := basePath + "/" + pname
	_,err:=os.Stat(basePath);if err != nil{
		//if doesn't have the dir, create it
		err:=os.MkdirAll(basePath,os.ModePerm); if err != nil{
			log.Printf("create directory %s failed: %s",basePath,err)
			w.Write([]byte(".....Failed, Create out_path failed.\n"))
			return
		}
	}

	
	//Here I just pass the "basePath" to the script, the shell will create "out_path"

	var script string
	var keyPath string
	switch platform {
	case "mtk":
		log.Println("Platform is mtk")
		script="/data/tools/repository/mtk_sign/sop_sign/kaios_key_generator.sh"
		keyPath=outPath + "/" + "root_prvk.pem"

	case "unisoc":
		log.Println("Platform is unisoc")
		script="/data/tools/repository/system/system-extern/sprd_sign/sop_sign_keys/kaios_key_generator_sprd.sh"
		keyPath=outPath + "/" + "dm_prvk.pem"

	default:
		log.Println("platform should be mtk or unisoc, Aborting")
		return
	}
	_,err=os.Stat(script)
	if err != nil || pname ==""{
		w.Write([]byte("script is not found\n"))
		return
	}
	args := []string{script,pname,basePath}
	cli:= strings.Join(args," ")
	//log.Println("r.Form is ",r.Form)
	log.Println("cli is ",cli)
	if err:=RunBash(cli,w);err != "nil"{
		log.Println("Run gen_key bash error",err)
		w.Write([]byte(".....Failed\n"))
		return
	}

	//Check if there is the PUBLIC_KEYS directory generated
	publicKeyPath:=outPath + "/" + "PUBLIC_KEYS"
	_,err=os.Stat(publicKeyPath)
	if err != nil {
		w.Write([]byte(".....Failed, no PUBLIC_KEYS\n"))
		log.Println("the publicKeyPath is ",publicKeyPath)
		return
	}

	log.Println("(3/5) Run Bash successfully")
	w.Write([]byte(".....OK\n"))

	//step4: insert pid,key,projectName and odmname to signature.secret
	//keyPath:=outPath + "/" + "root_prvk.pem"
	w.Write([]byte("STEP 3: Insert keys into DataBase"))
	if key,err:=ioutil.ReadFile(keyPath);err != nil{
		log.Println("Read key file fialed:",err)
		w.Write([]byte(".....failed\n"))
		return
	}else {
		//log.Println("key is ",key)
		err = db.InsertKey(pid, string(key), pname, odmName)
		if err == nil {
			log.Println("(4/5)Insert_Prvkey successfully")
		} else {
			log.Println("InsertKey Failed", err)
			w.Write([]byte(".....Failed\n"))
			return
		}
	}
	w.Write([]byte(".....OK\n"))

	//step5: insert the keys location to signature.location
	w.Write([]byte("STEP 4: Insert location to DataBase"))
	//rootKey:= outPath + "/" + "root_prvk.pem"
	//imageKey:= outPath + "/" + "img_prvk.pem"

	// here I only save the outpath
	err=db.Insert_Location_In_Signature(pid,outPath,outPath)
	if err == nil{
		log.Println("(5/5)Insert_Location successfully")
	}else {
		log.Println("Insert_Location failed",err)
		w.Write([]byte(".....Failed/n"))
	}
	w.Write([]byte(".....OK\n"))

	//step6: Package the Public_key directory
	w.Write([]byte("STEP 5: Zip the Public_key directory"))


	destzip:=fmt.Sprintf("%s/public_key.zip",outPath)
	ziperr:=Zip(publicKeyPath,destzip)
	if ziperr != nil{
		log.Println("zip error: \n",ziperr)
		w.Write([]byte(".....Failed,zip pulic_key failed\n"))
		w.Write([]byte(ziperr.Error()))
		return
	}
	w.Write([]byte(".....OK\n"))

	//** step7: uploaded the pulic_key.zip to ftp server
	w.Write([]byte("STEP 6: Uplode Zip to SFtp Server"))
	log.Println("+++++STEP 6: Uplode Zip to SFtp+++++\n")

	rootPath := fmt.Sprintf("/data/var/packages/%s/%s/",odmName,pname)
	releasePath := rootPath + "SWbuild_Release"
	err=f.Send(destzip,releasePath);if err !=nil{
		log.Printf("Upload Zip failed %s:,remote_path is %s",err,releasePath)
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte(err.Error()))
		return
	}
	log.Printf("Zip Successfully")
	w.Write([]byte(".....OK\n"))

	log.Println("Gen_key FINISH")
	end:=fmt.Sprintf("=====Gen_key completed for %s-%s=====\n\n",odmName,pname)
	w.Write([]byte(end))
}


//this function is used to signature and return
func Signature (w http.ResponseWriter, r *http.Request) {
	/*
		How to USE:
		1) curl -X POST http://127.0.0.1:6000/sign -d 'pid=100&file_name=package.zip'
	*/

	//** step0: customer upload the package to ftp server
	//customer upload package to rootPath(ftp server), sign_server will create the same dirs and fetch packages to it
	// sign programe will save the signed package into rootPath (sign server) and create the same dirs on ftp server
	// actually rootPath and rootPath will be created manually by me when the ODM ftp account is created (very first step)
	//example: rootPath:="/data/var/packages/odm1"
	//example: rootPath:="/data/var/packages/odm1/download"

	//** step1: Get the basic information of the package(in ftp server) from curl arguments

	log.Println("+++++STEP 1: Parse Form+++++\n")
	r.ParseForm()
	pid := r.FormValue("pid")
	//filename example: "xxx.zip"
	fileName := r.FormValue("file_name")
	preloader := r.FormValue("preloader")
	signda := r.FormValue("signda")
	efuse := r.FormValue("efuse")

	//platform is used to distinguish zhanrui or mtk platform
	platform := r.FormValue("platform")
	productName := r.FormValue("product_name")
	buildType := r.FormValue("build_type")

	fmt.Printf("pid is %s, filename is %s\n", pid, fileName)

	//split the unsigned file name
	now := time.Now().Format("20060102150405")
	suffix := path.Ext(fileName)
	prefix := fileName[0 : len(fileName)-len(suffix)]

	// search the project name with pid from eproject
	projectName, odmName, err := db.Query_Project_Odm_In_Eproject(pid)
	projectName = strings.Replace(projectName, " ", "_", -1)
	odmName = strings.Replace(odmName, " ", "_", -1)

	//daname is the n9th parameter passed to the signature script
	daname := odmName + "_" + projectName

	if err == sql.ErrNoRows {
		log.Println("Didn't find the projectName and odmName")
		return
	} else if err != nil {
		log.Println("Query_Project_Odm_In_Eproject error", err)
	}
	start := fmt.Sprintf("\n=====Start Signature for %s-%s=====\n", odmName, projectName)
	w.Write([]byte(start))
	w.Write([]byte("STEP 1: Parse Form"))

	if len(pid) == 0 || len(fileName) == 0 || len(platform) == 0 {
		log.Println("pid or filename or platform is empty")
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte("pid or filename or preloader or platform is empty\n"))
		return
	}
	log.Println("Parse Form Successfully")
	w.Write([]byte(".....OK\n"))

	//STEP2: Define and Create PATH
	//The Path topology on ftp_server and sign_server are the same as
	w.Write([]byte("STEP 2: Define and Create Path"))
	log.Println("+++++STEP 2: Define and Create Path+++++\n")
	rootPath := fmt.Sprintf("/data/var/packages/%s/%s/", odmName, projectName)
	inputPath := rootPath + "SWbuild_Input"
	candidatePath := rootPath + "SWbuild_Candidate"
	releasePath := rootPath + prefix + "_" + now
	daImagePath := "/data/tools/repository/dafolder_mt6731"
	preSignFile := inputPath + "/" + fileName
	dirList := []string{rootPath, inputPath, candidatePath, releasePath, daImagePath}
	for _, dir := range dirList {
		_, err := os.Stat(dir);
		if err != nil {
			//if doesn't have the dir, create it
			err := os.MkdirAll(dir, os.ModePerm);
			if err != nil {
				resp := fmt.Sprintf("create directory %s failed:%s", dir, err)
				log.Println(resp)
				w.Write([]byte(".....Failed\n"))
				w.Write([]byte(resp))
				return
			}
		}
	}
	w.Write([]byte(".....OK\n"))



	//** step2: signserver download the zip package from ftpserver, and saved into "rootPath + fileName"
	//rootPath is on ftp server, rootPath is on sign server, they are the same form
	w.Write([]byte("STEP 3: Fetch Zip File from FTP server"))
	log.Println("+++++STEP 3: Fetch Zip File+++++\n")

	//version 0.3 removed the info.json, no need to upload it again
	//fileList:=[]string{preSignFile,infoJson}
	log.Println("+++++STEP 3: Fetch Zip File+++++\n")
	downloadErr := f.Fetch(preSignFile, inputPath)
	if downloadErr != nil {
		log.Printf("Fetch package from ftp error: %s, dest is %s, local is %s", downloadErr, preSignFile, rootPath)
		w.Write([]byte(".....Failed\n"))
		fmt.Println("error is ", downloadErr)
		return
	}
	log.Printf("Fetch package dest is %s, local is %s", preSignFile, rootPath)
	log.Printf("Fetch %s File Successfully", preSignFile)
	w.Write([]byte(".....OK\n"))

	//**step3: unzip the package to the current directory
	//rootPath and rootPath will end with "/"
	//example: packagePath-> /data/var/package/odm1/xxxx.zip
	log.Println("+++++STEP 4: Unzip package+++++\n")
	w.Write([]byte("STEP 4: Unzip package"))
	//zipPath:=rootPath + fileName
	//preSignFile value is on ftp server, it is the same on signServer
	//Unzip the source zip to the dir where it located
	unzipErr := Unzip(preSignFile, inputPath)
	if unzipErr != nil {
		log.Println("unzip package error:", unzipErr)
		fmt.Printf("unziped the package from %s to %s", preSignFile, inputPath)
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte(unzipErr.Error()))
		return
	}

	log.Println("Unzip successfully")
	w.Write([]byte(".....OK\n"))

	//** step7: sign the package and save the signed package to {imageSignedPath} and {daImagePath}
	log.Println("+++++STEP 5: Signature! +++++\n")
	w.Write([]byte("STEP 5: Signature"))

	rootKey, imageKey, err2 := db.Query_Location_In_Signature(pid)
	if err2 != nil {
		log.Println("Query_Location_In_Signature error", err2)
	}

	var scriptPath string
	var args []string
	switch platform {
		case "mtk":
			if len(preloader) == 0 || len(signda) == 0 || len(efuse) == 0{
				log.Println("preloader or signda or efuse is empty")
				w.Write([]byte(".....Failed\n"))
				w.Write([]byte("pid or filename or preloader or signda or efuse is empty\n"))
				return
			}
			scriptPath = "/data/tools/repository/mtk_sign/kaios_key_sign.sh"
			args = []string{scriptPath, rootKey, imageKey, inputPath, releasePath, preloader, signda, daImagePath, efuse, daname}

		case "unisoc":

			if  len(productName) == 0 || len(buildType) == 0{
				log.Println("product_name or build_type is empty")
				w.Write([]byte(".....Failed\n"))
				w.Write([]byte("product_name or build_type is empty.\n"))
				return
			}

			scriptPath = "/data/tools/repository/system/system-extern/sprd_sign/kaios_key_sign_sprd.sh"
			sprdPath := "/data/tools/repository/system/system-extern/sprd_sign"
			args = []string{scriptPath, rootKey, inputPath, releasePath, sprdPath, productName, buildType}

	    default:
	    	w.Write([]byte(".....Failed\n"))
	    	w.Write([]byte("unknown platform, should be mtk or unisoc.\n"))
	    	return
    }

	log.Println("scriptPath should be..",scriptPath)
	_, err = os.Stat(scriptPath);
	if err != nil {
		w.Write([]byte(".....failed\n"))
		w.Write([]byte(err.Error()))
		return
	}

	cli:= strings.Join(args," ")
	log.Println("cli is ",cli)
	bashErr:=RunBash(cli,w)
	if bashErr != "nil"{
		log.Println("RunBash error: ",bashErr)
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte(bashErr))
		return
	}
	w.Write([]byte(".....OK\n"))
	//** step8: if signed successfully, insert the signed history into database
	log.Println("+++++STEP 6: Insert DB+++++\n")
	w.Write([]byte("STEP 6: Insert DB: sign_history"))
	queryErr:=db.Insert_Sign_History(pid,projectName,odmName,true)
	if queryErr != nil{
		log.Printf("[Error],signature failed, error is: %v",queryErr)
		Response(500,queryErr,"writeDB")
		//return
	}
	log.Printf("Insert DB Successfully")
	w.Write([]byte(".....OK\n"))

	//** step9: zip {imageSignedPath}
	log.Println("+++++STEP 7: Zip the Signed Files+++++\n")
	w.Write([]byte("STEP 7: Zip the Signed Files"))

	//generate the ziped file name.

    //compress the signed files and save to destzip
	destzip:=fmt.Sprintf("%s/%s_%s.zip",candidatePath,prefix,now)
	log.Println("signed file name is", destzip)

	//20200727:remove the source package from releasePath before compress if exsit
	sourcePackage:= releasePath + "/" + fileName
	_,err=os.Stat(sourcePackage)
	if err == nil{
		log.Println("Found Source file in release dir!")
		if err=os.Remove(sourcePackage); err == nil{
			log.Println("Removed the source package:",sourcePackage)
		}else {
			log.Println("Failed removed the source package:",err)
		}
	}else{
		log.Println("Didn't Found Source file in release dir,no need to delete.")

	}
	ziperr:=Zip(releasePath,destzip)
	if ziperr != nil{
		log.Println("zip error:",ziperr)
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte(ziperr.Error()))
		return
	}

	fd,err:=os.Stat(destzip)
	//signedFileName:=fd.Name()
	if err!=nil || int(fd.Size()) < 100{
		log.Println("The ziped file size is wrong, or error when zip:",err)
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte(err.Error()))
		return
	}
	log.Printf("Zip Successfully")
	w.Write([]byte(".....OK\n"))

	//** step10: uploaded the signed package to ftp server
	w.Write([]byte("STEP 8: Uplode Zip to Ftp Server"))
	log.Println("+++++STEP 8: Uplode Zip to Ftp+++++\n")
	//downloadPath:=rootPath + "download" + "/" + signedFileName
	err=f.Send(destzip,candidatePath);if err !=nil{
		log.Printf("Upload Zip failed %s:,remote_path is %s",err,candidatePath)
		w.Write([]byte(".....Failed\n"))
		w.Write([]byte(err.Error()))
		return
	}
	log.Printf("Upload Successfully")
	w.Write([]byte(".....OK\n"))
	end:=fmt.Sprintf("=====Signature completed for %s-%s=====\n\n",odmName,projectName)
	w.Write([]byte(end))
}


