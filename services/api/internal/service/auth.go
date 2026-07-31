package service

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

var ErrCodeTooFrequent = errors.New("verification code requested too frequently")

type Mailer interface {
	SendVerificationCode(context.Context, string, string) error
}

type DevelopmentMailer struct{}

func (DevelopmentMailer) SendVerificationCode(context.Context, string, string) error {
	slog.Info("verification email accepted by development mailer")
	return nil
}

type AuthService struct {
	database *pgxpool.Pool
	redis    *redis.Client
	mailer   Mailer
	secret   []byte
}

func NewAuthService(database *pgxpool.Pool, redisClient *redis.Client, mailer Mailer, secret string) *AuthService {
	return &AuthService{database: database, redis: redisClient, mailer: mailer, secret: []byte(secret)}
}

func (s *AuthService) SendEmailCode(ctx context.Context, email string) (err error) {
	normalizedEmail := strings.ToLower(strings.TrimSpace(email))
	rateKey := "auth:email-code:" + hashText(normalizedEmail)
	allowed, err := s.redis.SetNX(ctx, rateKey, "1", time.Minute).Result()
	if err != nil {
		return fmt.Errorf("set email rate limit: %w", err)
	}
	if !allowed {
		return ErrCodeTooFrequent
	}
	defer func() {
		if err != nil {
			s.redis.Del(ctx, rateKey)
		}
	}()

	code, err := verificationCode()
	if err != nil {
		return err
	}
	var codeID string
	err = s.database.QueryRow(ctx, `
		INSERT INTO email_verification_codes (email, code_hash, purpose, expired_at)
		VALUES ($1, $2, 'login', $3)
		RETURNING id
	`, normalizedEmail, s.hashCode(code), time.Now().Add(10*time.Minute)).Scan(&codeID)
	if err != nil {
		return fmt.Errorf("store verification code: %w", err)
	}
	if err = s.mailer.SendVerificationCode(ctx, normalizedEmail, code); err != nil {
		if _, cleanupErr := s.database.Exec(ctx, "DELETE FROM email_verification_codes WHERE id = $1", codeID); cleanupErr != nil {
			slog.Error("failed to remove undelivered verification code")
		}
		return fmt.Errorf("send verification code: %w", err)
	}
	return nil
}

func (s *AuthService) hashCode(code string) string {
	hash := hmac.New(sha256.New, s.secret)
	hash.Write([]byte(code))
	return hex.EncodeToString(hash.Sum(nil))
}

func verificationCode() (string, error) {
	number, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", fmt.Errorf("generate verification code: %w", err)
	}
	return fmt.Sprintf("%06d", number.Int64()), nil
}

func hashText(value string) string {
	hash := sha256.Sum256([]byte(value))
	return hex.EncodeToString(hash[:])
}
