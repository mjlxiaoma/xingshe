package app

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
	"github.com/mjlxiaoma/xingshe/services/api/internal/middleware"
)

func TestHealthz(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)

	NewRouter(handler.NewAuthHandler(nil)).ServeHTTP(recorder, request)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}
	want := `{"code":"OK","message":"success","data":{"status":"ok"}}`
	if recorder.Body.String() != want {
		t.Fatalf("body = %s, want %s", recorder.Body.String(), want)
	}
	if recorder.Header().Get(middleware.RequestIDHeader) == "" {
		t.Fatal("missing request ID")
	}
}

func TestNotFoundUsesErrorContract(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	NewRouter(handler.NewAuthHandler(nil)).ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/missing", nil))

	want := `{"code":"RESOURCE_NOT_FOUND","message":"资源不存在","data":null}`
	if recorder.Code != http.StatusNotFound || recorder.Body.String() != want {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}
