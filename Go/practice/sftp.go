package main


import (
"fmt"
"github.com/pkg/sftp"
"golang.org/x/crypto/ssh"
"log"
"os"
"path"
"time"
)

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
	}

	// connet to ssh
	addr = fmt.Sprintf("%s:%d", host, port)

	if sshClient, err = ssh.Dial("tcp", addr, clientConfig); err != nil {
		return nil, err
	}

	// create sftp client
	if sftpClient, err = sftp.NewClient(sshClient); err != nil {
		return nil, err
	}

	return sftpClient, nil
}

func Send() {

	var (
		err        error
		sftpClient *sftp.Client
	)

	// 这里换成实际的 SSH 连接的 用户名，密码，主机名或IP，SSH端口
	sftpClient, err = connect("root", "Kai@2019!", "10.81.74.99", 22)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("connect ok")
	defer sftpClient.Close()

	// 用来测试的本地文件路径 和 远程机器上的文件夹
	var localFilePath = "/home/yuxiao/subpo-1.9.3.tar.bz2"
	var remoteDir = "/tmp"
	srcFile, err := os.Open(localFilePath)
	if err != nil {
		log.Fatal(err)
	}
	defer srcFile.Close()

	var remoteFileName = path.Base(localFilePath)
	dstFile, err := sftpClient.Create(path.Join(remoteDir, remoteFileName))
	if err != nil {
		log.Fatal(err)
	}
	defer dstFile.Close()
	fmt.Println("here is ok")

	buf := make([]byte, 1024)
	for {
		n, _ := srcFile.Read(buf)
		if n == 0 {
			break
		}
		dstFile.Write(buf)
	}

	fmt.Println("copy file to remote server finished!")
}


func Fetch() {

	var (
		err        error
		sftpClient *sftp.Client
	)

	sftpClient, err = connect("root", "Kai@2019!", "10.81.74.99", 890)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("C is OK")
	defer sftpClient.Close()

	var remoteFilePath = "/tmp/subpo-1.9.3.tar.bz2"
	var localDir = "/tmp/test"

	srcFile, err := sftpClient.Open(remoteFilePath)
	if err != nil {
		log.Fatal(err)
	}
	defer srcFile.Close()

	var localFileName = path.Base(remoteFilePath)
	dstFile, err := os.Create(path.Join(localDir, localFileName))
	if err != nil {
		log.Fatal(err)
	}
	defer dstFile.Close()

	fmt.Println("Start copy...")
	if _, err = srcFile.WriteTo(dstFile); err != nil {
		log.Fatal(err)
	}

	fmt.Println("copy file from remote server finished!")
}

func main(){
	//Send()
	Fetch()
}