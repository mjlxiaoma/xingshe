package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestRecoveryReturnsRequestIDAndInternalError(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	router.Use(RequestID(), Recovery())
	router.GET("/panic", func(*gin.Context) { panic("test") })
	recorder := httptest.NewRecorder()

	router.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/panic", nil))

	if recorder.Header().Get(RequestIDHeader) == "" {
		t.Fatal("missing request ID")
	}
	want := `{"code":"INTERNAL_ERROR","message":"服务器内部错误","data":null}`
	if recorder.Code != http.StatusInternalServerError || recorder.Body.String() != want {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}
