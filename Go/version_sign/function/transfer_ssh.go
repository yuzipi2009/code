package function

import (
	"fmt"
	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
	"log"
	"os"
	"path"
	"strconv"
	"time"
	"version_sign/initiation"
)

type Fs interface {
	Fetch(dstFile,localDir string) (fetchErr error)
	Send(srcFile,dstDir string) (senderr error)
}

type Project struct {}

// sftpClient will be used by Fetch() and send()
var SftpClient *sftp.Client
var sfterr error
//This is thr 2nd init to connect to sftp server
func init (){
	sftpHost:= initiation.C.TransFile["host"]
	sftpUser:= initiation.C.TransFile["username"]
	sftpPass:= initiation.C.TransFile["password"]
	sftpPort,_:=strconv.Atoi(initiation.C.TransFile["port"])

	SftpClient,sfterr = connect(sftpUser, sftpPass, sftpHost, sftpPort)
	if sfterr!=nil {
		panic(sfterr)
	}
	fmt.Println("++++I should be the 2nd init, I'm sftp.++++")
}


func connect(user, password, host string, port int) (*sftp.Client, error) {

	var (
		auth         []ssh.AuthMethod
		addr         string
		clientConfig *ssh.ClientConfig
		sshClient    *ssh.Client
		sftpClient   *sftp.Client
		err          error
	)
	// get auth method
	auth = make([]ssh.AuthMethod, 0)
	auth = append(auth, ssh.Password(password))

	clientConfig = &ssh.ClientConfig{
		User:    user,
		Auth:    auth,
		Timeout: 30 * time.Second,
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	// connet to ssh
	addr = fmt.Sprintf("%s:%d", host, port)

	if sshClient, err = ssh.Dial("tcp", addr, clientConfig,); err != nil {
		return nil, err
	}

	// create sftp client
	if sftpClient, err = sftp.NewClient(sshClient); err != nil {
		return nil, err
	}

	return sftpClient, nil
}

func (p Project) Send(srcFile,dstDir string) (senderr error) {
	file, err := os.Open(srcFile)
	if err != nil {
		return err
	}
	defer file.Close()

	var fileName = path.Base(srcFile)
	dstFile, err := SftpClient.Create(path.Join(dstDir, fileName))
	if err != nil {
		return err
	}
	defer dstFile.Close()

	buf := make([]byte, 1024)
	for {
		n, _ := file.Read(buf)
		if n == 0 {
			break
		}
		dstFile.Write(buf)
	}

	log.Println("copy file to remote server finished!")
	return nil
}


func (p Project)Fetch(dstFile,localDir string) (fetchErr error){

	srcFile, err := SftpClient.Open(dstFile)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	var localFileName = path.Base(dstFile)
	localFile, err := os.Create(path.Join(localDir, localFileName))
	if err != nil {
		//log.Fatal(err)
		return err
	}
	defer localFile.Close()

	if _, err = srcFile.WriteTo(localFile); err != nil {
		//log.Fatal(err)
		return err
	}

	log.Println("copy file from remote server finished!")
	return nil
}
