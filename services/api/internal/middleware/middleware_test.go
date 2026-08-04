package middleware

import (
	"bytes"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestRecoveryReturnsRequestIDAndInternalError(t *testing.T) {
	var logs bytes.Buffer
	previous := slog.Default()
	slog.SetDefault(slog.New(slog.NewJSONHandler(&logs, nil)))
	defer slog.SetDefault(previous)
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(RequestID(), Logger(), Recovery())
	router.GET("/panic", func(*gin.Context) { panic("test-secret-token") })
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/panic?code=123456&email=person@example.invalid", nil)
	request.Header.Set("Authorization", "Bearer test-secret-token")
	router.ServeHTTP(recorder, request)

	if recorder.Header().Get(RequestIDHeader) == "" {
		t.Fatal("missing request ID")
	}
	want := `{"code":"INTERNAL_ERROR","message":"服务器内部错误","data":null}`
	if recorder.Code != http.StatusInternalServerError || recorder.Body.String() != want {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	output := logs.String()
	for _, sensitive := range []string{"test-secret-token", "123456", "person@example.invalid", "Authorization", "code="} {
		if strings.Contains(output, sensitive) {
			t.Fatalf("log contains sensitive value %q", sensitive)
		}
	}
	for _, safe := range []string{"request completed", "panic recovered", "/panic"} {
		if !strings.Contains(output, safe) {
			t.Fatalf("log does not contain %q", safe)
		}
	}
}
