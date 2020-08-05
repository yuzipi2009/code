package main

import (
	"archive/zip"
	"bytes"
	"fmt"
	"log"
	"os/exec"
	"strings"

	//"log"
	"io"
	"os"
	"path/filepath"
)

func isZip(zipPath string) bool {
	f, err := os.Open(zipPath)
	if err != nil {
		return false
	}
	defer f.Close()

	buf := make([]byte, 4)
	if n, err := f.Read(buf); err != nil || n < 4 {
		return false
	}

	return bytes.Equal(buf, []byte("PK\x03\x04"))
}


func Unzip(archive, destPath string) error {
	reader, err := zip.OpenReader(archive)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(destPath, 0755); err != nil {
		return err
	}

	for _, file := range reader.File {
		path := filepath.Join(destPath, file.Name)
		if file.FileInfo().IsDir() {
			os.MkdirAll(path, file.Mode())
			continue
		}

		fileReader, err := file.Open()
		if err != nil {
			return err
		}
		defer fileReader.Close()

		targetFile, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, file.Mode())
		if err != nil {
			return err
		}
		defer targetFile.Close()

		if _, err := io.Copy(targetFile, fileReader); err != nil {
			return err
		}
	}

	return nil
}


// srcFile could be a single file or a directory
func Zip(srcFile string, destZip string) error {
	zipfile, err := os.Create(destZip)
	if err != nil {
		return err
	}
	defer zipfile.Close()

	archive := zip.NewWriter(zipfile)
	defer archive.Close()

	filepath.Walk(srcFile, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		header, err := zip.FileInfoHeader(info)
		if err != nil {
			return err
		}


		header.Name = strings.TrimPrefix(path, filepath.Dir(srcFile) + "/")
		// header.Name = path
		if info.IsDir() {
			header.Name += "/"
		} else {
			header.Method = zip.Deflate
		}

		writer, err := archive.CreateHeader(header)
		if err != nil {
			return err
		}

		if ! info.IsDir() {
			file, err := os.Open(path)
			if err != nil {
				return err
			}
			defer file.Close()
			fmt.Println("start copy",file)
			_, err = io.Copy(writer, file)
		}
		return err
	})
    fmt.Println("finished!")
	return err
}

func zip2 (a string){
	cli:=fmt.Sprintf("cd /tmp/text: zip -r %s.zip *",a)
	exec.Command("/bin/bash", "-c", `zip -r  `)
}
func main ()  {

	odmName:="Waterworld"
	projectName:="Erbium-E241S"
	//fileName:= "20200507.zip"
	rootPath := fmt.Sprintf("/data/var/packages/%s/%s/",odmName,projectName)
	//inputPath := rootPath + "SWbuild_Input"
	releasePath := rootPath + "SWbuild_Release"
	///daImagePath:= rootPath + "da"
	//preSignFile:=inputPath + "/" + fileName
	candidatePath := rootPath + "SWbuild_Candidate"


	destzip:=fmt.Sprintf("%s/signed_%s.zip",candidatePath,projectName)
	fmt.Println("start....")
	ziperr:=Zip(releasePath,destzip)
	if ziperr != nil{
		log.Println("zip error:",ziperr)
		return
	}

}