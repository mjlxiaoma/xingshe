package handler

import "github.com/gin-gonic/gin"

type Response struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data"`
}

const (
	CodeOK               = "OK"
	CodeValidationError  = "VALIDATION_ERROR"
	CodeResourceNotFound = "RESOURCE_NOT_FOUND"
	CodeInternalError    = "INTERNAL_ERROR"
	CodeCodeTooFrequent  = "AUTH_CODE_TOO_FREQUENT"
	CodeCodeInvalid      = "AUTH_CODE_INVALID"
	CodeCodeExpired      = "AUTH_CODE_EXPIRED"
	CodeInvalidToken     = "AUTH_INVALID_TOKEN"
	CodeUnauthorized     = "AUTH_UNAUTHORIZED"
	CodeRateLimited      = "RATE_LIMITED"
)

func JSON(c *gin.Context, status int, code string, message string, data any) {
	c.JSON(status, Response{Code: code, Message: message, Data: data})
}

func Error(c *gin.Context, status int, code string, message string) {
	JSON(c, status, code, message, nil)
}
