package app

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
	"github.com/mjlxiaoma/xingshe/services/api/internal/middleware"
	"github.com/mjlxiaoma/xingshe/services/api/internal/service"
)

func NewRouter(authHandler *handler.AuthHandler, authService *service.AuthService, spotHandler *handler.SpotHandler) *gin.Engine {
	router := gin.New()
	router.Use(middleware.RequestID(), middleware.Logger(), middleware.Recovery())
	router.GET("/healthz", func(c *gin.Context) {
		handler.JSON(c, http.StatusOK, handler.CodeOK, "success", gin.H{"status": "ok"})
	})
	authRoutes := router.Group("/api/v1/auth")
	authRoutes.POST("/email-code", authHandler.SendEmailCode)
	authRoutes.POST("/login", authHandler.Login)
	authRoutes.POST("/refresh", authHandler.Refresh)
	authRoutes.POST("/logout", authHandler.Logout)
	meRoutes := router.Group("/api/v1/me", middleware.Authenticate(authService))
	meRoutes.GET("", authHandler.Me)
	meRoutes.PATCH("", authHandler.UpdateMe)
	meRoutes.DELETE("", authHandler.DeleteMe)
	meRoutes.GET("/favorite-spots", spotHandler.Favorites)
	spots := router.Group("/api/v1/spots", middleware.OptionalAuthenticate(authService))
	spots.GET("", spotHandler.List)
	spots.GET("/:spotId", spotHandler.Detail)
	protectedSpots := router.Group("/api/v1/spots", middleware.Authenticate(authService))
	protectedSpots.POST("/:spotId/favorite", spotHandler.Favorite)
	protectedSpots.DELETE("/:spotId/favorite", spotHandler.Unfavorite)
	router.NoRoute(func(c *gin.Context) {
		handler.Error(c, http.StatusNotFound, handler.CodeResourceNotFound, "资源不存在")
	})
	return router
}
