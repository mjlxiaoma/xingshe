package main

import (
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/app"
	"github.com/mjlxiaoma/xingshe/services/api/internal/config"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
	gin.SetMode(gin.ReleaseMode)

	cfg, err := config.Load()
	if err != nil {
		logger.Error("invalid configuration", "error", err)
		os.Exit(1)
	}
	server := &http.Server{
		Addr:              cfg.Address,
		Handler:           app.NewRouter(),
		ReadHeaderTimeout: 5 * time.Second,
	}
	logger.Info("api starting", "address", cfg.Address, "environment", cfg.Environment)
	if err := server.ListenAndServe(); err != nil {
		logger.Error("api stopped", "error", err)
		os.Exit(1)
	}
}
