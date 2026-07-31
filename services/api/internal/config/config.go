package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	Address      string
	Environment  string
	DatabaseURL  string
	RedisAddress string
	JWTSecret    string
	SMTPHost     string
	SMTPPort     int
	SMTPUser     string
	SMTPPassword string
	SMTPFrom     string
}

func Load() (Config, error) {
	apiPort, err := port("API_PORT", 8080)
	if err != nil {
		return Config{}, err
	}
	smtpPort, err := port("SMTP_PORT", 587)
	if err != nil {
		return Config{}, err
	}
	environment := strings.TrimSpace(os.Getenv("APP_ENV"))
	if environment == "" {
		environment = "development"
	}
	redisAddress := strings.TrimSpace(os.Getenv("REDIS_ADDR"))
	if redisAddress == "" {
		redisAddress = "127.0.0.1:6379"
	}
	jwtSecret := os.Getenv("JWT_SECRET")
	if len(jwtSecret) < 32 || jwtSecret == "replace-with-at-least-32-random-characters" {
		return Config{}, errors.New("JWT_SECRET must be a unique value with at least 32 characters")
	}
	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		return Config{}, errors.New("DATABASE_URL is required")
	}
	return Config{
		Address:      fmt.Sprintf(":%d", apiPort),
		Environment:  environment,
		DatabaseURL:  databaseURL,
		RedisAddress: redisAddress,
		JWTSecret:    jwtSecret,
		SMTPHost:     strings.TrimSpace(os.Getenv("SMTP_HOST")),
		SMTPPort:     smtpPort,
		SMTPUser:     strings.TrimSpace(os.Getenv("SMTP_USER")),
		SMTPPassword: os.Getenv("SMTP_PASSWORD"),
		SMTPFrom:     strings.TrimSpace(os.Getenv("SMTP_FROM")),
	}, nil
}

func port(name string, fallback int) (int, error) {
	value := strings.TrimSpace(os.Getenv(name))
	if value == "" {
		return fallback, nil
	}
	parsed, err := strconv.Atoi(value)
	if err != nil || parsed < 1 || parsed > 65535 {
		return 0, fmt.Errorf("%s must be a port between 1 and 65535", name)
	}
	return parsed, nil
}
