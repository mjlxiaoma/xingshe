package main

import (
	"log"
	"net/http"
	"time"

	"github.com/mjlxiaoma/xingshe/services/api/internal/app"
	"github.com/mjlxiaoma/xingshe/services/api/internal/config"
)

func main() {
	cfg := config.Load()
	server := &http.Server{
		Addr:              cfg.Address,
		Handler:           app.NewRouter(),
		ReadHeaderTimeout: 5 * time.Second,
	}
	log.Fatal(server.ListenAndServe())
}
