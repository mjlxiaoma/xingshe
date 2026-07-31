package handler

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/service"
)

type AuthHandler struct {
	auth *service.AuthService
}

func NewAuthHandler(auth *service.AuthService) *AuthHandler {
	return &AuthHandler{auth: auth}
}

func (h *AuthHandler) SendEmailCode(c *gin.Context) {
	var request struct {
		Email string `json:"email" binding:"required,email,max=255"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		Error(c, http.StatusBadRequest, CodeValidationError, "邮箱格式不正确")
		return
	}
	if err := h.auth.SendEmailCode(c.Request.Context(), strings.ToLower(strings.TrimSpace(request.Email))); err != nil {
		if errors.Is(err, service.ErrCodeTooFrequent) {
			Error(c, http.StatusTooManyRequests, CodeCodeTooFrequent, "验证码发送过于频繁，请稍后再试")
			return
		}
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", gin.H{})
}
