package config

import "testing"

func TestLoadDefaultsAndValidatesPorts(t *testing.T) {
	t.Run("defaults", func(t *testing.T) {
		t.Setenv("API_PORT", "")
		t.Setenv("SMTP_PORT", "")
		cfg, err := Load()
		if err != nil {
			t.Fatal(err)
		}
		if cfg.Address != ":8080" || cfg.SMTPPort != 587 {
			t.Fatalf("address = %s, SMTP port = %d", cfg.Address, cfg.SMTPPort)
		}
	})

	t.Run("invalid API port", func(t *testing.T) {
		t.Setenv("API_PORT", "70000")
		if _, err := Load(); err == nil {
			t.Fatal("expected invalid API_PORT error")
		}
	})
}
