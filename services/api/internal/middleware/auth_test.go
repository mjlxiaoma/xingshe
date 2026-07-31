package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/service"
)

func TestAuthenticateProtectsRoute(t *testing.T) {
	gin.SetMode(gin.TestMode)
	auth := service.NewAuthService(nil, nil, nil, "0123456789abcdef0123456789abcdef", 2*time.Hour, 30*24*time.Hour)
	token, err := auth.NewAccessToken("user-id")
	if err != nil {
		t.Fatal(err)
	}
	router := gin.New()
	router.Use(Authenticate(auth))
	router.GET("/protected", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	unauthorized := httptest.NewRecorder()
	router.ServeHTTP(unauthorized, httptest.NewRequest(http.MethodGet, "/protected", nil))
	if unauthorized.Code != http.StatusUnauthorized {
		t.Fatalf("missing token status = %d", unauthorized.Code)
	}

	authorized := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/protected", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	router.ServeHTTP(authorized, request)
	if authorized.Code != http.StatusNoContent {
		t.Fatalf("valid token status = %d", authorized.Code)
	}
}

func TestOptionalAuthenticateAllowsAnonymousAndRejectsInvalidToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	auth := service.NewAuthService(nil, nil, nil, "0123456789abcdef0123456789abcdef", 2*time.Hour, 30*24*time.Hour)
	router := gin.New()
	router.Use(OptionalAuthenticate(auth))
	router.GET("/public", func(c *gin.Context) { c.Status(http.StatusNoContent) })

	anonymous := httptest.NewRecorder()
	router.ServeHTTP(anonymous, httptest.NewRequest(http.MethodGet, "/public", nil))
	if anonymous.Code != http.StatusNoContent {
		t.Fatalf("anonymous status = %d", anonymous.Code)
	}
	invalid := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/public", nil)
	request.Header.Set("Authorization", "Bearer invalid")
	router.ServeHTTP(invalid, request)
	if invalid.Code != http.StatusUnauthorized {
		t.Fatalf("invalid token status = %d", invalid.Code)
	}
}
