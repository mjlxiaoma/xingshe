package service

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"
)

var (
	ErrCodeTooFrequent  = errors.New("verification code requested too frequently")
	ErrCodeInvalid      = errors.New("verification code is invalid")
	ErrCodeExpired      = errors.New("verification code is expired")
	ErrInvalidToken     = errors.New("token is invalid")
	ErrLoginRateLimited = errors.New("login attempts are rate limited")
	ErrUserNotFound     = errors.New("user not found")
)

type Mailer interface {
	SendVerificationCode(context.Context, string, string) error
}

type DevelopmentMailer struct{}

func (DevelopmentMailer) SendVerificationCode(context.Context, string, string) error {
	slog.Info("verification email accepted by development mailer")
	return nil
}

type User struct {
	ID        string  `json:"id"`
	Email     string  `json:"email"`
	Nickname  string  `json:"nickname"`
	AvatarURL *string `json:"avatar_url"`
}

type Session struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
	User         User   `json:"user"`
}

type RefreshedSession struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"`
}

type AuthService struct {
	database   *pgxpool.Pool
	redis      *redis.Client
	mailer     Mailer
	secret     []byte
	accessTTL  time.Duration
	refreshTTL time.Duration
}

func NewAuthService(database *pgxpool.Pool, redisClient *redis.Client, mailer Mailer, secret string, accessTTL, refreshTTL time.Duration) *AuthService {
	return &AuthService{
		database: database, redis: redisClient, mailer: mailer, secret: []byte(secret),
		accessTTL: accessTTL, refreshTTL: refreshTTL,
	}
}

func (s *AuthService) SendEmailCode(ctx context.Context, email string) (err error) {
	normalizedEmail := normalizeEmail(email)
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
	tx, err := s.database.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	if _, err := tx.Exec(ctx, `
		UPDATE email_verification_codes SET consumed_at = now()
		WHERE email = $1 AND purpose = 'login' AND consumed_at IS NULL
	`, normalizedEmail); err != nil {
		return fmt.Errorf("invalidate verification codes: %w", err)
	}
	var codeID string
	err = tx.QueryRow(ctx, `
		INSERT INTO email_verification_codes (email, code_hash, purpose, expired_at)
		VALUES ($1, $2, 'login', $3)
		RETURNING id
	`, normalizedEmail, s.hash(code), time.Now().Add(10*time.Minute)).Scan(&codeID)
	if err != nil {
		return fmt.Errorf("store verification code: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return err
	}
	if err = s.mailer.SendVerificationCode(ctx, normalizedEmail, code); err != nil {
		if _, cleanupErr := s.database.Exec(ctx, "DELETE FROM email_verification_codes WHERE id = $1", codeID); cleanupErr != nil {
			slog.Error("failed to remove undelivered verification code")
		}
		return fmt.Errorf("send verification code: %w", err)
	}
	return nil
}

func (s *AuthService) Login(ctx context.Context, email, code, deviceID string) (Session, error) {
	tx, err := s.database.Begin(ctx)
	if err != nil {
		return Session{}, err
	}
	defer tx.Rollback(ctx)

	normalizedEmail := normalizeEmail(email)
	var codeID, codeHash string
	var expiresAt time.Time
	err = tx.QueryRow(ctx, `
		SELECT id, code_hash, expired_at
		FROM email_verification_codes
		WHERE email = $1 AND purpose = 'login' AND consumed_at IS NULL
		ORDER BY created_at DESC
		LIMIT 1
		FOR UPDATE
	`, normalizedEmail).Scan(&codeID, &codeHash, &expiresAt)
	if errors.Is(err, pgx.ErrNoRows) {
		if rateErr := s.recordLoginAttempt(ctx, normalizedEmail); rateErr != nil {
			return Session{}, rateErr
		}
		return Session{}, ErrCodeInvalid
	}
	if err != nil {
		return Session{}, err
	}
	if err := s.recordLoginAttempt(ctx, normalizedEmail); err != nil {
		return Session{}, err
	}
	if !expiresAt.After(time.Now()) {
		return Session{}, ErrCodeExpired
	}
	if !hmac.Equal([]byte(codeHash), []byte(s.hash(code))) {
		return Session{}, ErrCodeInvalid
	}
	if _, err := tx.Exec(ctx, "UPDATE email_verification_codes SET consumed_at = now() WHERE id = $1", codeID); err != nil {
		return Session{}, err
	}

	var user User
	err = tx.QueryRow(ctx, `
		INSERT INTO users (email, nickname)
		VALUES ($1, '摄影爱好者')
		ON CONFLICT (email) DO UPDATE SET email = EXCLUDED.email
		RETURNING id, email, nickname, avatar_url
	`, normalizedEmail).Scan(&user.ID, &user.Email, &user.Nickname, &user.AvatarURL)
	if err != nil {
		return Session{}, err
	}
	accessToken, refreshToken, err := s.newTokens(user.ID)
	if err != nil {
		return Session{}, err
	}
	if err := s.insertRefreshToken(ctx, tx, user.ID, deviceID, refreshToken); err != nil {
		return Session{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return Session{}, err
	}
	s.redis.Del(ctx, loginAttemptKey(normalizedEmail))
	return Session{AccessToken: accessToken, RefreshToken: refreshToken, ExpiresIn: int64(s.accessTTL.Seconds()), User: user}, nil
}

func (s *AuthService) Refresh(ctx context.Context, refreshToken, deviceID string) (RefreshedSession, error) {
	tx, err := s.database.Begin(ctx)
	if err != nil {
		return RefreshedSession{}, err
	}
	defer tx.Rollback(ctx)

	var tokenID, userID, storedDeviceID string
	var expiresAt time.Time
	err = tx.QueryRow(ctx, `
		SELECT id, user_id, device_id, expired_at
		FROM refresh_tokens
		WHERE token_hash = $1 AND revoked_at IS NULL
		FOR UPDATE
	`, s.hash(refreshToken)).Scan(&tokenID, &userID, &storedDeviceID, &expiresAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return RefreshedSession{}, ErrInvalidToken
	}
	if err != nil {
		return RefreshedSession{}, err
	}
	if storedDeviceID != deviceID || !expiresAt.After(time.Now()) {
		return RefreshedSession{}, ErrInvalidToken
	}
	if _, err := tx.Exec(ctx, "UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1", tokenID); err != nil {
		return RefreshedSession{}, err
	}
	accessToken, newRefreshToken, err := s.newTokens(userID)
	if err != nil {
		return RefreshedSession{}, err
	}
	if err := s.insertRefreshToken(ctx, tx, userID, deviceID, newRefreshToken); err != nil {
		return RefreshedSession{}, err
	}
	if err := tx.Commit(ctx); err != nil {
		return RefreshedSession{}, err
	}
	return RefreshedSession{AccessToken: accessToken, RefreshToken: newRefreshToken, ExpiresIn: int64(s.accessTTL.Seconds())}, nil
}

func (s *AuthService) Logout(ctx context.Context, refreshToken string) error {
	result, err := s.database.Exec(ctx, `
		UPDATE refresh_tokens SET revoked_at = now()
		WHERE token_hash = $1 AND revoked_at IS NULL
	`, s.hash(refreshToken))
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		return ErrInvalidToken
	}
	return nil
}

func (s *AuthService) CurrentUser(ctx context.Context, userID string) (User, error) {
	var user User
	err := s.database.QueryRow(ctx, `
		SELECT id, email, nickname, avatar_url
		FROM users
		WHERE id = $1 AND status = 1
	`, userID).Scan(&user.ID, &user.Email, &user.Nickname, &user.AvatarURL)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrUserNotFound
	}
	return user, err
}

func (s *AuthService) UpdateNickname(ctx context.Context, userID, nickname string) (User, error) {
	var user User
	err := s.database.QueryRow(ctx, `
		UPDATE users
		SET nickname = $2, updated_at = now()
		WHERE id = $1 AND status = 1
		RETURNING id, email, nickname, avatar_url
	`, userID, nickname).Scan(&user.ID, &user.Email, &user.Nickname, &user.AvatarURL)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrUserNotFound
	}
	return user, err
}

func (s *AuthService) NewAccessToken(userID string) (string, error) {
	now := time.Now()
	claims := jwt.RegisteredClaims{
		Issuer: "xingshe-api", Subject: userID, Audience: jwt.ClaimStrings{"xingshe-mobile"},
		IssuedAt: jwt.NewNumericDate(now), NotBefore: jwt.NewNumericDate(now), ExpiresAt: jwt.NewNumericDate(now.Add(s.accessTTL)),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(s.secret)
}

func (s *AuthService) VerifyAccessToken(value string) (string, error) {
	claims := &jwt.RegisteredClaims{}
	token, err := jwt.ParseWithClaims(value, claims, func(token *jwt.Token) (any, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, ErrInvalidToken
		}
		return s.secret, nil
	}, jwt.WithIssuer("xingshe-api"), jwt.WithAudience("xingshe-mobile"), jwt.WithExpirationRequired())
	if err != nil || !token.Valid || claims.Subject == "" {
		return "", ErrInvalidToken
	}
	return claims.Subject, nil
}

func (s *AuthService) newTokens(userID string) (string, string, error) {
	accessToken, err := s.NewAccessToken(userID)
	if err != nil {
		return "", "", err
	}
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", "", err
	}
	return accessToken, base64.RawURLEncoding.EncodeToString(bytes), nil
}

func (s *AuthService) insertRefreshToken(ctx context.Context, tx pgx.Tx, userID, deviceID, refreshToken string) error {
	_, err := tx.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, device_id, expired_at)
		VALUES ($1, $2, $3, $4)
	`, userID, s.hash(refreshToken), deviceID, time.Now().Add(s.refreshTTL))
	return err
}

func (s *AuthService) recordLoginAttempt(ctx context.Context, email string) error {
	key := loginAttemptKey(email)
	var attempts *redis.IntCmd
	_, err := s.redis.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
		attempts = pipe.Incr(ctx, key)
		pipe.Expire(ctx, key, 10*time.Minute)
		return nil
	})
	if err != nil {
		return err
	}
	if attempts.Val() > 5 {
		return ErrLoginRateLimited
	}
	return nil
}

func (s *AuthService) hash(value string) string {
	hash := hmac.New(sha256.New, s.secret)
	hash.Write([]byte(value))
	return hex.EncodeToString(hash.Sum(nil))
}

func verificationCode() (string, error) {
	number, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", fmt.Errorf("generate verification code: %w", err)
	}
	return fmt.Sprintf("%06d", number.Int64()), nil
}

func normalizeEmail(value string) string {
	return strings.ToLower(strings.TrimSpace(value))
}

func hashText(value string) string {
	hash := sha256.Sum256([]byte(value))
	return hex.EncodeToString(hash[:])
}

func loginAttemptKey(email string) string {
	return "auth:login-attempt:" + hashText(email)
}
