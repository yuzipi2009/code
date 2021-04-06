package function

import (
	"fmt"
	"github.com/jlaffaye/ftp"
	ftp2 "github.com/martinr92/goftp"
	"github.com/pkg/errors"
	"io"
	"log"
	"os"
	"time"
)

/*
type Fs interface {
	Upload()
	Download()
}

type ODM struct {
	name string
}

 */


//this function is used to upload signed package from sign_server to ftp_server
func  Upload_With_Ftp(src,dest string) {

	//var toFtp string
	//var fromServer string


	//if string(src[len(src)-1]) != "/" || string(dest[len(dest)-1]) != "/" {
	//	panic ("The path should end with '/'")

	//}else {
	//	srcfile:=src + file
	//	destfile:=dest + file
	//	log.Println(srcfile,destfile)
	//}

	ftpClient,err:=ftp2.NewFtp("10.81.74.99:21")
	if err != nil{
		panic(err)
	}

	defer ftpClient.Close()
	log.Println("(1/4)Connected to ftp server")
	if err = ftpClient.Login("Admin", "Kaios@3151"); err != nil {
		panic(err)
	}
    log.Println("(2/4)Auth Verified Pass")

	// directory name is like /data/var/package/{odm}/{project}
	//directory:=odmname + "/" + projectname
	if err = ftpClient.OpenDirectory(dest); err != nil {
		panic(err)
	}
	log.Println("(3/4)Changed directory successfuly")

	if err = ftpClient.Upload(src,dest); err != nil {
		panic(err)
	}
	log.Println("(4/4)Uploded successfully")
}

/*
func vsftp() {

	config := &ssh.ClientConfig{
		User:            "odm",
		HostKeyCallback: nil,
		Auth: []ssh.AuthMethod{
			ssh.Password("odm"),
		},
	}

	config.SetDefaults()
	sshConn, err := ssh.Dial("tcp", "10.81.74.99:22", config)
	if err != nil {
		panic(err)
	}
	log.Println("Connected")
	defer sshConn.Close()

	client, err := sftp.NewClient(sshConn)
	if err != nil {
		panic(err)
	}
	defer client.Close()

	srcFile, err := client.Open("/data/var/packages/upload_packages/haproxy-1.8.8.tar.bz2")
	if err != nil {
		panic(err)
	}
	log.Println("opened source dile")
	defer srcFile.Close()

	// Create the destination file
	dstFile, err := os.Create("/tmp/haproxy.tar.bz2")
	if err != nil {
		log.Fatal(err)
	}
	defer dstFile.Close()
	if _, err := srcFile.WriteTo(dstFile); err != nil {
		log.Fatal(err)
	}

	log.Println("copied")
}


 */

func Download_With_Ftp (ftpPath,serverPath,file string) (err error){

	var fromFtp string
	var toServer string


	if string(serverPath[len(serverPath)-1]) != "/" || string(ftpPath[len(ftpPath)-1]) != "/" {
		err := errors.New("ftp_path or server_path should end with '/'")
		return err
	}else {
		fromFtp=serverPath + file
		toServer=ftpPath + file
		log.Println(fromFtp,toServer)
	}

	fmt.Println("started")
	c, err := ftp.Dial("10.81.74.99:21", ftp.DialWithTimeout(5*time.Second))
	fmt.Println(c,err)
	if err != nil {
		fmt.Println("dial err is ",err)
		log.Fatal(err)
		return err
	}
    log.Println("Connected")

	err = c.Login("test", "test")
	if err != nil {
		log.Fatal(err)
		return err
	}
	log.Println("Logined")

	// Do something with the FTP conn
	ftpFile, err := c.Retr(fromFtp)
	if err != nil {
		return err
	}
	log.Println("Read source")

	localFile,err:=os.Create(toServer)
	if err!=nil{
		log.Println("os.Create error",err)
		return err
	}
	defer localFile.Close()
	log.Println("Created local")

	_, err = io.Copy(localFile, ftpFile)
	if err != nil {
    	log.Println("io.Copy error")
    	return err
	}
	log.Println("Finished")

	if err := c.Quit(); err != nil {
		return err
	}

	return nil
}

