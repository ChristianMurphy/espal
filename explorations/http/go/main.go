// The Go net/http reference for the HTTP spike, written as the net/http docs recommend.
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

type message struct {
	Message string `json:"message"`
}

func main() {
	port := "8080"
	if len(os.Args) > 1 {
		port = os.Args[1]
	}
	mux := http.NewServeMux()
	mux.HandleFunc("/plaintext", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Server", "Go")
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte("Hello, World!"))
	})
	mux.HandleFunc("/json", func(w http.ResponseWriter, r *http.Request) {
		body, err := json.Marshal(message{Message: "Hello, World!"})
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.Header().Set("Server", "Go")
		w.Header().Set("Content-Type", "application/json")
		w.Write(body)
	})
	log.Fatal(http.ListenAndServe(":"+port, mux))
}
