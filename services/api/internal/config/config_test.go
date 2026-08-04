package config

import (
	"testing"
	"time"
)

func TestLoadDefaultsAndValidatesPorts(t *testing.T) {
	t.Setenv("JWT_SECRET", "0123456789abcdef0123456789abcdef")
	t.Setenv("DATABASE_URL", "postgres://example")
	t.Setenv("SMTP_HOST", "")
	t.Setenv("SMTP_USER", "")
	t.Setenv("SMTP_PASSWORD", "")
	t.Setenv("SMTP_FROM", "")
	t.Run("defaults", func(t *testing.T) {
		t.Setenv("API_PORT", "")
		t.Setenv("SMTP_PORT", "")
		t.Setenv("JWT_ACCESS_TTL", "")
		t.Setenv("JWT_REFRESH_TTL", "")
		cfg, err := Load()
		if err != nil {
			t.Fatal(err)
		}
		if cfg.Address != ":8080" || cfg.SMTPPort != 465 || cfg.AccessTTL != 2*time.Hour || cfg.RefreshTTL != 30*24*time.Hour {
			t.Fatalf("address = %s, SMTP port = %d", cfg.Address, cfg.SMTPPort)
		}
	})

	t.Run("partial SMTP configuration", func(t *testing.T) {
		t.Setenv("SMTP_HOST", "smtp.example.com")
		if _, err := Load(); err == nil {
			t.Fatal("expected partial SMTP configuration error")
		}
	})

	t.Run("invalid API port", func(t *testing.T) {
		t.Setenv("API_PORT", "70000")
		if _, err := Load(); err == nil {
			t.Fatal("expected invalid API_PORT error")
		}
	})

	t.Run("placeholder JWT secret", func(t *testing.T) {
		t.Setenv("JWT_SECRET", "replace-with-at-least-32-random-characters")
		if _, err := Load(); err == nil {
			t.Fatal("expected placeholder JWT_SECRET error")
		}
	})
}
