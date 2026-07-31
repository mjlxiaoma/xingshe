package app

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
	"github.com/mjlxiaoma/xingshe/services/api/internal/middleware"
)

func NewRouter(auth *handler.AuthHandler) *gin.Engine {
	router := gin.New()
	router.Use(middleware.RequestID(), middleware.Logger(), middleware.Recovery())
	router.GET("/healthz", func(c *gin.Context) {
		handler.JSON(c, http.StatusOK, handler.CodeOK, "success", gin.H{"status": "ok"})
	})
	router.POST("/api/v1/auth/email-code", auth.SendEmailCode)
	router.NoRoute(func(c *gin.Context) {
		handler.Error(c, http.StatusNotFound, handler.CodeResourceNotFound, "资源不存在")
	})
	return router
}
