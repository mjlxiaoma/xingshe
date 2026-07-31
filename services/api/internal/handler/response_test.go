package handler

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestValidationErrorResponse(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	router := gin.New()
	router.GET("/", func(c *gin.Context) {
		Error(c, http.StatusBadRequest, CodeValidationError, "请求参数有误")
	})

	router.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/", nil))

	want := `{"code":"VALIDATION_ERROR","message":"请求参数有误","data":null}`
	if recorder.Code != http.StatusBadRequest || recorder.Body.String() != want {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}
