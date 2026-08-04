package middleware

import (
	"context"
	"crypto/rand"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
)

type AccessTokenAuthenticator interface {
	AuthenticateAccessToken(context.Context, string) (string, error)
}

const (
	RequestIDKey    = "request_id"
	RequestIDHeader = "X-Request-ID"
	UserIDKey       = "user_id"
)

func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := rand.Text()
		c.Set(RequestIDKey, requestID)
		c.Header(RequestIDHeader, requestID)
		c.Next()
	}
}

func Authenticate(auth AccessTokenAuthenticator) gin.HandlerFunc {
	return func(c *gin.Context) {
		parts := strings.Fields(c.GetHeader("Authorization"))
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			handler.Error(c, http.StatusUnauthorized, handler.CodeUnauthorized, "请先登录")
			c.Abort()
			return
		}
		userID, err := auth.AuthenticateAccessToken(c.Request.Context(), parts[1])
		if err != nil {
			handler.Error(c, http.StatusUnauthorized, handler.CodeInvalidToken, "登录已失效，请重新登录")
			c.Abort()
			return
		}
		c.Set(UserIDKey, userID)
		c.Next()
	}
}

func OptionalAuthenticate(auth AccessTokenAuthenticator) gin.HandlerFunc {
	return func(c *gin.Context) {
		if strings.TrimSpace(c.GetHeader("Authorization")) == "" {
			c.Next()
			return
		}
		parts := strings.Fields(c.GetHeader("Authorization"))
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			handler.Error(c, http.StatusUnauthorized, handler.CodeInvalidToken, "登录已失效，请重新登录")
			c.Abort()
			return
		}
		userID, err := auth.AuthenticateAccessToken(c.Request.Context(), parts[1])
		if err != nil {
			handler.Error(c, http.StatusUnauthorized, handler.CodeInvalidToken, "登录已失效，请重新登录")
			c.Abort()
			return
		}
		c.Set(UserIDKey, userID)
		c.Next()
	}
}

func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		started := time.Now()
		c.Next()
		slog.Info("request completed",
			"request_id", c.GetString(RequestIDKey),
			"method", c.Request.Method,
			"path", c.Request.URL.Path,
			"status", c.Writer.Status(),
			"duration_ms", time.Since(started).Milliseconds(),
		)
	}
}

func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if recover() != nil {
				slog.Error("panic recovered", "request_id", c.GetString(RequestIDKey))
				handler.Error(c, http.StatusInternalServerError, handler.CodeInternalError, "服务器内部错误")
				c.Abort()
			}
		}()
		c.Next()
	}
}
