package service

import (
	"regexp"
	"testing"
)

func TestVerificationCodeAndHash(t *testing.T) {
	code, err := verificationCode()
	if err != nil {
		t.Fatal(err)
	}
	if !regexp.MustCompile(`^\d{6}$`).MatchString(code) {
		t.Fatalf("code has invalid format")
	}
	service := &AuthService{secret: []byte("0123456789abcdef0123456789abcdef")}
	hash := service.hashCode(code)
	if hash == code || hash != service.hashCode(code) {
		t.Fatal("verification code hash is not deterministic and non-plaintext")
	}
}
