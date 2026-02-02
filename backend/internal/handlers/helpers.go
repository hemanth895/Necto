package handlers

import (
	"encoding/json"
	"net/http"
	"strings"
)

func jsonDecode(r *http.Request, v interface{}) error {
	return json.NewDecoder(r.Body).Decode(v)
}

func trim(s string) string {
	return strings.TrimSpace(s)
}
