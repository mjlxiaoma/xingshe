package app

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
	"github.com/mjlxiaoma/xingshe/services/api/internal/service"
	"github.com/redis/go-redis/v9"
)

type captureMailer struct {
	code string
}

func (mailer *captureMailer) SendVerificationCode(_ context.Context, _, code string) error {
	mailer.code = code
	return nil
}

type apiResponse[T any] struct {
	Code string `json:"code"`
	Data T      `json:"data"`
}

func TestMVPAPIFlow(t *testing.T) {
	databaseURL := os.Getenv("TEST_DATABASE_URL")
	redisAddress := os.Getenv("TEST_REDIS_ADDR")
	if databaseURL == "" || redisAddress == "" {
		t.Skip("TEST_DATABASE_URL and TEST_REDIS_ADDR are required for integration tests")
	}
	ctx := context.Background()
	database, err := pgxpool.New(ctx, databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	redisClient := redis.NewClient(&redis.Options{Addr: redisAddress, DB: 15})
	defer redisClient.Close()

	email := strings.ToLower(rand.Text()) + "@example.invalid"
	defer func() {
		redisClient.Del(ctx, redisAuthKey("auth:email-code:", email), redisAuthKey("auth:login-attempt:", email))
		database.Exec(ctx, "DELETE FROM users WHERE email = $1", email)
		database.Exec(ctx, "DELETE FROM email_verification_codes WHERE email = $1", email)
	}()
	mailer := &captureMailer{}
	auth := service.NewAuthService(database, redisClient, mailer, "integration-test-secret-32-characters", 2*time.Hour, 30*24*time.Hour)
	spots := service.NewSpotService(database)
	gin.SetMode(gin.TestMode)
	server := httptest.NewServer(NewRouter(handler.NewAuthHandler(auth), auth, handler.NewSpotHandler(spots)))
	defer server.Close()

	requestError(t, server.URL, http.MethodPost, "/api/v1/auth/email-code", map[string]any{"email": "invalid"}, "", http.StatusBadRequest, handler.CodeValidationError)
	requestError(t, server.URL, http.MethodPost, "/api/v1/auth/login", map[string]any{"email": email, "code": "1", "device_id": ""}, "", http.StatusBadRequest, handler.CodeValidationError)
	requestError(t, server.URL, http.MethodGet, "/api/v1/spots?latitude=1", nil, "", http.StatusBadRequest, handler.CodeValidationError)
	requestError(t, server.URL, http.MethodGet, "/api/v1/spots/not-a-uuid", nil, "", http.StatusBadRequest, handler.CodeValidationError)
	requestError(t, server.URL, http.MethodGet, "/api/v1/me", nil, "", http.StatusUnauthorized, handler.CodeUnauthorized)

	requestAPI[map[string]any](t, server.URL, http.MethodPost, "/api/v1/auth/email-code", map[string]any{"email": email}, "")
	if len(mailer.code) != 6 {
		t.Fatal("verification code was not captured")
	}
	session := requestAPI[service.Session](t, server.URL, http.MethodPost, "/api/v1/auth/login", map[string]any{
		"email": email, "code": mailer.code, "device_id": "integration-device",
	}, "")
	refreshed := requestAPI[service.RefreshedSession](t, server.URL, http.MethodPost, "/api/v1/auth/refresh", map[string]any{
		"refresh_token": session.RefreshToken, "device_id": "integration-device",
	}, "")
	requestError(t, server.URL, http.MethodPost, "/api/v1/auth/refresh", map[string]any{
		"refresh_token": session.RefreshToken, "device_id": "integration-device",
	}, "", http.StatusUnauthorized, handler.CodeInvalidToken)
	currentUser := requestAPI[service.User](t, server.URL, http.MethodGet, "/api/v1/me", nil, refreshed.AccessToken)
	if currentUser.Email != email {
		t.Fatalf("unexpected current user: %+v", currentUser)
	}
	user := requestAPI[service.User](t, server.URL, http.MethodPatch, "/api/v1/me", map[string]any{"nickname": "Integration User"}, refreshed.AccessToken)
	if user.Email != email || user.Nickname != "Integration User" {
		t.Fatalf("unexpected user: %+v", user)
	}
	spotList := requestAPI[service.SpotList](t, server.URL, http.MethodGet, "/api/v1/spots?page_size=1", nil, refreshed.AccessToken)
	if spotList.Total < 10 || len(spotList.Items) != 1 {
		t.Fatalf("unexpected spot list: %+v", spotList)
	}
	spotID := spotList.Items[0].ID
	requestAPI[map[string]any](t, server.URL, http.MethodPost, "/api/v1/spots/"+spotID+"/favorite", nil, refreshed.AccessToken)
	requestAPI[map[string]any](t, server.URL, http.MethodPost, "/api/v1/spots/"+spotID+"/favorite", nil, refreshed.AccessToken)
	detail := requestAPI[service.Spot](t, server.URL, http.MethodGet, "/api/v1/spots/"+spotID, nil, refreshed.AccessToken)
	if !detail.IsFavorited {
		t.Fatal("detail did not return favorite state")
	}
	favorites := requestAPI[struct {
		Items []service.Spot `json:"items"`
	}](t, server.URL, http.MethodGet, "/api/v1/me/favorite-spots", nil, refreshed.AccessToken)
	if len(favorites.Items) != 1 || favorites.Items[0].ID != spotID {
		t.Fatalf("unexpected favorites: %+v", favorites.Items)
	}
	requestAPI[map[string]any](t, server.URL, http.MethodDelete, "/api/v1/spots/"+spotID+"/favorite", nil, refreshed.AccessToken)
	favorites = requestAPI[struct {
		Items []service.Spot `json:"items"`
	}](t, server.URL, http.MethodGet, "/api/v1/me/favorite-spots", nil, refreshed.AccessToken)
	if len(favorites.Items) != 0 {
		t.Fatalf("favorite was not removed: %+v", favorites.Items)
	}
	requestAPI[map[string]any](t, server.URL, http.MethodPost, "/api/v1/spots/"+spotID+"/favorite", nil, refreshed.AccessToken)
	requestAPI[map[string]any](t, server.URL, http.MethodPost, "/api/v1/auth/logout", map[string]any{"refresh_token": refreshed.RefreshToken}, "")
	requestError(t, server.URL, http.MethodPost, "/api/v1/auth/refresh", map[string]any{
		"refresh_token": refreshed.RefreshToken, "device_id": "integration-device",
	}, "", http.StatusUnauthorized, handler.CodeInvalidToken)
	requestAPI[map[string]any](t, server.URL, http.MethodDelete, "/api/v1/me", nil, refreshed.AccessToken)
	requestError(t, server.URL, http.MethodGet, "/api/v1/me", nil, refreshed.AccessToken, http.StatusUnauthorized, handler.CodeInvalidToken)

	var users, codes, tokens, favoriteRows int
	if err := database.QueryRow(ctx, `
		SELECT
			(SELECT count(*) FROM users WHERE email = $1),
			(SELECT count(*) FROM email_verification_codes WHERE email = $1),
			(SELECT count(*) FROM refresh_tokens WHERE user_id = $2),
			(SELECT count(*) FROM user_favorite_spots WHERE user_id = $2)
	`, email, user.ID).Scan(&users, &codes, &tokens, &favoriteRows); err != nil {
		t.Fatal(err)
	}
	if users != 0 || codes != 0 || tokens != 0 || favoriteRows != 0 {
		t.Fatalf("account data remains: users=%d codes=%d tokens=%d favorites=%d", users, codes, tokens, favoriteRows)
	}
}

func requestAPI[T any](t *testing.T, baseURL, method, path string, body any, token string) T {
	t.Helper()
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		reader = bytes.NewReader(encoded)
	}
	request, err := http.NewRequest(method, baseURL+path, reader)
	if err != nil {
		t.Fatal(err)
	}
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		payload, _ := io.ReadAll(response.Body)
		t.Fatalf("%s %s: status %d, body %s", method, path, response.StatusCode, payload)
	}
	var envelope apiResponse[T]
	if err := json.NewDecoder(response.Body).Decode(&envelope); err != nil {
		t.Fatal(err)
	}
	if envelope.Code != handler.CodeOK {
		t.Fatalf("%s %s: code %s", method, path, envelope.Code)
	}
	return envelope.Data
}

func requestError(t *testing.T, baseURL, method, path string, body any, token string, status int, code string) {
	t.Helper()
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			t.Fatal(err)
		}
		reader = bytes.NewReader(encoded)
	}
	request, err := http.NewRequest(method, baseURL+path, reader)
	if err != nil {
		t.Fatal(err)
	}
	if body != nil {
		request.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		request.Header.Set("Authorization", "Bearer "+token)
	}
	response, err := http.DefaultClient.Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	var envelope apiResponse[any]
	if err := json.NewDecoder(response.Body).Decode(&envelope); err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != status || envelope.Code != code {
		t.Fatalf("%s %s: status %d, code %s", method, path, response.StatusCode, envelope.Code)
	}
}

func redisAuthKey(prefix, email string) string {
	return prefix + fmt.Sprintf("%x", sha256.Sum256([]byte(email)))
}
