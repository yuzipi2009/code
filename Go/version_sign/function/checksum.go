package function

import (
	"crypto/md5"
	"encoding/hex"
	"github.com/pkg/errors"
	"io"
	"log"
	"os"
)


//this function will return a string of md5check
func md5sum (filepath string) string{
	src,err:=os.Open(filepath)
	if err != nil {
		log.Println("MD5:Open source error",err)
	}

	h:=md5.New()
	io.Copy(h,src)
	return hex.EncodeToString(h.Sum(nil))

}

func compareMd5 (srcMd5,filePath string) error{
	desMd5:= md5sum(filePath)
	if srcMd5==desMd5{
		log.Println("Md5checksum PASS")
		return nil
	}else {
		log.Println("Md5checksum failed, package may corrupted")
		return errors.New("md5 check failed, the package may corrupt, " +
			"ask customer upload again")
	}
}