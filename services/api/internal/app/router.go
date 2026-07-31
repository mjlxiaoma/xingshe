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
	authRoutes := router.Group("/api/v1/auth")
	authRoutes.POST("/email-code", auth.SendEmailCode)
	authRoutes.POST("/login", auth.Login)
	authRoutes.POST("/refresh", auth.Refresh)
	authRoutes.POST("/logout", auth.Logout)
	router.NoRoute(func(c *gin.Context) {
		handler.Error(c, http.StatusNotFound, handler.CodeResourceNotFound, "资源不存在")
	})
	return router
}
