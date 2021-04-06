package function

import (
	"net/http"
	"version_sign/db"

)

func ValidateLogin (w http.ResponseWriter, r *http.Request) {
	name := r.FormValue("login")
	pw := r.FormValue("pw")

	hashName := Hash(name)
	hashPw := Hash(pw)

	p, _ := db.QueryAccount(hashName)
	//if n != hashName || p != hashPw {
	if p != hashPw {
		w.Write([]byte("login_name or password is wrong!"))
		return
	}
}






