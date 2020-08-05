package main

import (
"fmt"
"path"
)
func main() {
	filename := "device/sdk/CMakeLists.txt"
	nameall := path.Base(filename)
	suffix := path.Ext(filename)
	prefix := nameall[0:len(nameall) - len(suffix)]
	//fileprefix, err := strings.TrimSuffix(filenameall, filesuffix)

	fmt.Println("file name:", nameall)
	fmt.Println("file prefix:", prefix)
	fmt.Println("file suffix:", suffix)
}