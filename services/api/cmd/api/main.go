package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mjlxiaoma/xingshe/services/api/internal/app"
	"github.com/mjlxiaoma/xingshe/services/api/internal/config"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
	"github.com/mjlxiaoma/xingshe/services/api/internal/service"
	"github.com/redis/go-redis/v9"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
	gin.SetMode(gin.ReleaseMode)

	if err := run(); err != nil {
		logger.Error("api stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("invalid configuration: %w", err)
	}
	var mailer service.Mailer = service.DevelopmentMailer{}
	if cfg.SMTPHost != "" {
		mailer, err = service.NewSMTPMailer(cfg.SMTPHost, cfg.SMTPPort, cfg.SMTPUser, cfg.SMTPPassword, cfg.SMTPFrom)
		if err != nil {
			return fmt.Errorf("invalid SMTP configuration: %w", err)
		}
	} else if cfg.Environment == "production" {
		return errors.New("SMTP configuration is required in production")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	database, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return errors.New("database configuration is invalid")
	}
	defer database.Close()
	if err := database.Ping(ctx); err != nil {
		return errors.New("database is unavailable")
	}
	redisClient := redis.NewClient(&redis.Options{Addr: cfg.RedisAddress})
	defer redisClient.Close()
	if err := redisClient.Ping(ctx).Err(); err != nil {
		return errors.New("Redis is unavailable")
	}
	auth := service.NewAuthService(database, redisClient, mailer, cfg.JWTSecret, cfg.AccessTTL, cfg.RefreshTTL)
	authHandler := handler.NewAuthHandler(auth)
	spots := service.NewSpotService(database)
	server := &http.Server{
		Addr:              cfg.Address,
		Handler:           app.NewRouter(authHandler, auth, handler.NewSpotHandler(spots)),
		ReadHeaderTimeout: 5 * time.Second,
	}
	slog.Info("api starting", "address", cfg.Address, "environment", cfg.Environment)
	return server.ListenAndServe()
}
