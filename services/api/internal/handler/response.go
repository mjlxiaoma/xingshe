package handler

import "github.com/gin-gonic/gin"

type Response struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	Data    any    `json:"data"`
}

func JSON(c *gin.Context, status int, code string, message string, data any) {
	c.JSON(status, Response{Code: code, Message: message, Data: data})
}
