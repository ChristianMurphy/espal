// The Go reference for the Postgres spike: net/http with pgx, as their docs recommend.
package main

import (
	"context"
	"encoding/json"
	"log"
	"math/rand/v2"
	"net/http"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"
)

type world struct {
	ID           int32 `json:"id"`
	RandomNumber int32 `json:"randomNumber"`
}

func main() {
	port := "8080"
	if len(os.Args) > 1 {
		port = os.Args[1]
	}
	pool, err := pgxpool.New(context.Background(),
		"postgres://benchmarkdbuser:benchmarkdbpass@127.0.0.1:5432/hello_world?pool_max_conns=16")
	if err != nil {
		log.Fatal(err)
	}
	http.HandleFunc("/db", func(w http.ResponseWriter, r *http.Request) {
		var row world
		err := pool.QueryRow(r.Context(), "SELECT id, randomnumber FROM world WHERE id = $1",
			rand.IntN(10000)+1).Scan(&row.ID, &row.RandomNumber)
		if err != nil {
			http.Error(w, err.Error(), http.StatusServiceUnavailable)
			return
		}
		body, _ := json.Marshal(row)
		w.Header().Set("Server", "Go")
		w.Header().Set("Content-Type", "application/json")
		w.Write(body)
	})
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
