package service

import (
	"regexp"
	"testing"
	"time"
)

func TestVerificationCodeAndHash(t *testing.T) {
	code, err := verificationCode()
	if err != nil {
		t.Fatal(err)
	}
	if !regexp.MustCompile(`^\d{6}$`).MatchString(code) {
		t.Fatalf("code has invalid format")
	}
	service := &AuthService{secret: []byte("0123456789abcdef0123456789abcdef"), accessTTL: 2 * time.Hour}
	hash := service.hash(code)
	if hash == code || hash != service.hash(code) {
		t.Fatal("verification code hash is not deterministic and non-plaintext")
	}
	accessToken, err := service.NewAccessToken("user-id")
	if err != nil {
		t.Fatal(err)
	}
	userID, err := service.VerifyAccessToken(accessToken)
	if err != nil || userID != "user-id" {
		t.Fatalf("user ID = %q, error = %v", userID, err)
	}
	if _, err := service.VerifyAccessToken(accessToken + "tampered"); err == nil {
		t.Fatal("expected tampered access token error")
	}
	expired := &AuthService{secret: service.secret, accessTTL: -time.Second}
	expiredToken, err := expired.NewAccessToken("user-id")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := expired.VerifyAccessToken(expiredToken); err == nil {
		t.Fatal("expected expired access token error")
	}
}
