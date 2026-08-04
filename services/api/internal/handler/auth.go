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

func (h *AuthHandler) Login(c *gin.Context) {
	var request struct {
		Email    string `json:"email" binding:"required,email,max=255"`
		Code     string `json:"code" binding:"required,len=6,numeric"`
		DeviceID string `json:"device_id" binding:"required,max=128"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		Error(c, http.StatusBadRequest, CodeValidationError, "请求参数有误")
		return
	}
	session, err := h.auth.Login(c.Request.Context(), request.Email, request.Code, request.DeviceID)
	if errors.Is(err, service.ErrCodeInvalid) {
		Error(c, http.StatusBadRequest, CodeCodeInvalid, "验证码不正确")
		return
	}
	if errors.Is(err, service.ErrCodeExpired) {
		Error(c, http.StatusBadRequest, CodeCodeExpired, "验证码已过期")
		return
	}
	if errors.Is(err, service.ErrLoginRateLimited) {
		Error(c, http.StatusTooManyRequests, CodeRateLimited, "尝试次数过多，请稍后再试")
		return
	}
	if err != nil {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", session)
}

func (h *AuthHandler) Refresh(c *gin.Context) {
	var request struct {
		RefreshToken string `json:"refresh_token" binding:"required,max=512"`
		DeviceID     string `json:"device_id" binding:"required,max=128"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		Error(c, http.StatusBadRequest, CodeValidationError, "请求参数有误")
		return
	}
	session, err := h.auth.Refresh(c.Request.Context(), request.RefreshToken, request.DeviceID)
	if errors.Is(err, service.ErrInvalidToken) {
		Error(c, http.StatusUnauthorized, CodeInvalidToken, "登录已失效，请重新登录")
		return
	}
	if err != nil {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", session)
}

func (h *AuthHandler) Logout(c *gin.Context) {
	var request struct {
		RefreshToken string `json:"refresh_token" binding:"required,max=512"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		Error(c, http.StatusBadRequest, CodeValidationError, "请求参数有误")
		return
	}
	if err := h.auth.Logout(c.Request.Context(), request.RefreshToken); err != nil && !errors.Is(err, service.ErrInvalidToken) {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", gin.H{})
}

func (h *AuthHandler) Me(c *gin.Context) {
	user, err := h.auth.CurrentUser(c.Request.Context(), c.GetString("user_id"))
	h.userResponse(c, user, err)
}

func (h *AuthHandler) UpdateMe(c *gin.Context) {
	var request struct {
		Nickname string `json:"nickname" binding:"required,min=1,max=64"`
	}
	if err := c.ShouldBindJSON(&request); err != nil || strings.TrimSpace(request.Nickname) == "" {
		Error(c, http.StatusBadRequest, CodeValidationError, "昵称长度必须为 1 到 64 个字符")
		return
	}
	user, err := h.auth.UpdateNickname(c.Request.Context(), c.GetString("user_id"), strings.TrimSpace(request.Nickname))
	h.userResponse(c, user, err)
}

func (h *AuthHandler) DeleteMe(c *gin.Context) {
	if err := h.auth.DeleteAccount(c.Request.Context(), c.GetString("user_id")); errors.Is(err, service.ErrUserNotFound) {
		Error(c, http.StatusNotFound, CodeResourceNotFound, "用户不存在")
	} else if err != nil {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
	} else {
		JSON(c, http.StatusOK, CodeOK, "success", gin.H{})
	}
}

func (h *AuthHandler) userResponse(c *gin.Context, user service.User, err error) {
	if errors.Is(err, service.ErrUserNotFound) {
		Error(c, http.StatusNotFound, CodeResourceNotFound, "用户不存在")
		return
	}
	if err != nil {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", user)
}
