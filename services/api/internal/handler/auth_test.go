package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
)

func TestSendEmailCodeRejectsInvalidEmail(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	router := gin.New()
	handler := NewAuthHandler(nil)
	router.POST("/email-code", handler.SendEmailCode)
	request := httptest.NewRequest(http.MethodPost, "/email-code", strings.NewReader(`{"email":"invalid"}`))
	request.Header.Set("Content-Type", "application/json")

	router.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusBadRequest || !strings.Contains(recorder.Body.String(), CodeValidationError) {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}

func TestUpdateMeRejectsInvalidNickname(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	router := gin.New()
	router.PATCH("/me", NewAuthHandler(nil).UpdateMe)
	request := httptest.NewRequest(http.MethodPatch, "/me", strings.NewReader(`{"nickname":"   "}`))
	request.Header.Set("Content-Type", "application/json")

	router.ServeHTTP(recorder, request)

	if recorder.Code != http.StatusBadRequest || !strings.Contains(recorder.Body.String(), CodeValidationError) {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
}
