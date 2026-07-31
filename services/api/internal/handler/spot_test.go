package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestSpotListRejectsInvalidQuery(t *testing.T) {
	gin.SetMode(gin.TestMode)
	for _, query := range []string{
		"?latitude=31",
		"?latitude=91&longitude=120",
		"?radius=1000",
		"?page=0",
		"?page_size=101",
	} {
		recorder := httptest.NewRecorder()
		router := gin.New()
		router.GET("/spots", NewSpotHandler(nil).List)
		router.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/spots"+query, nil))
		if recorder.Code != http.StatusBadRequest || !strings.Contains(recorder.Body.String(), CodeValidationError) {
			t.Fatalf("query %q: status = %d, body = %s", query, recorder.Code, recorder.Body.String())
		}
	}
}

func TestSpotDetailRejectsInvalidID(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	router := gin.New()
	router.GET("/spots/:spotId", NewSpotHandler(nil).Detail)
	router.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, "/spots/not-a-uuid", nil))
	if recorder.Code != http.StatusBadRequest || !strings.Contains(recorder.Body.String(), CodeValidationError) {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}
