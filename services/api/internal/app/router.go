package app

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/handler"
)

func NewRouter() *gin.Engine {
	router := gin.New()
	router.Use(gin.Logger(), gin.Recovery())
	router.GET("/healthz", func(c *gin.Context) {
		handler.JSON(c, http.StatusOK, "OK", "success", gin.H{"status": "ok"})
	})
	return router
}
