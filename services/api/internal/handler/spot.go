package handler

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/mjlxiaoma/xingshe/services/api/internal/service"
)

type SpotHandler struct {
	spots *service.SpotService
}

func NewSpotHandler(spots *service.SpotService) *SpotHandler {
	return &SpotHandler{spots: spots}
}

func (h *SpotHandler) List(c *gin.Context) {
	var request struct {
		Latitude  *float64 `form:"latitude" binding:"omitempty,gte=-90,lte=90"`
		Longitude *float64 `form:"longitude" binding:"omitempty,gte=-180,lte=180"`
		Radius    *float64 `form:"radius" binding:"omitempty,gt=0,lte=500000"`
		Keyword   string   `form:"keyword" binding:"max=128"`
		Page      *int     `form:"page" binding:"omitempty,min=1"`
		PageSize  *int     `form:"page_size" binding:"omitempty,min=1,max=100"`
	}
	if err := c.ShouldBindQuery(&request); err != nil ||
		(request.Latitude == nil) != (request.Longitude == nil) ||
		(request.Radius != nil && request.Latitude == nil) {
		Error(c, http.StatusBadRequest, CodeValidationError, "查询参数有误")
		return
	}
	page, pageSize := 1, 20
	if request.Page != nil {
		page = *request.Page
	}
	if request.PageSize != nil {
		pageSize = *request.PageSize
	}
	radius := 50000.0
	if request.Radius != nil {
		radius = *request.Radius
	}
	result, err := h.spots.List(c.Request.Context(), service.SpotQuery{
		Latitude: request.Latitude, Longitude: request.Longitude, Radius: radius,
		Keyword: strings.TrimSpace(request.Keyword), Page: page, PageSize: pageSize,
	})
	if err != nil {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", result)
}

func (h *SpotHandler) Detail(c *gin.Context) {
	var request struct {
		SpotID string `uri:"spotId" binding:"required,uuid"`
	}
	if err := c.ShouldBindUri(&request); err != nil {
		Error(c, http.StatusBadRequest, CodeValidationError, "机位编号格式不正确")
		return
	}
	spot, err := h.spots.Get(c.Request.Context(), request.SpotID)
	if errors.Is(err, service.ErrSpotNotFound) {
		Error(c, http.StatusNotFound, CodeResourceNotFound, "机位不存在")
		return
	}
	if err != nil {
		Error(c, http.StatusInternalServerError, CodeInternalError, "服务器内部错误")
		return
	}
	JSON(c, http.StatusOK, CodeOK, "success", spot)
}
