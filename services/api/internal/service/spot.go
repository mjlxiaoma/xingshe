package service

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrSpotNotFound = errors.New("shooting spot not found")

type Spot struct {
	ID               string   `json:"id"`
	Name             string   `json:"name"`
	Description      string   `json:"description"`
	Latitude         float64  `json:"latitude"`
	Longitude        float64  `json:"longitude"`
	CoordinateSystem string   `json:"coordinate_system"`
	Address          *string  `json:"address"`
	CoverURL         *string  `json:"cover_url"`
	BestTime         *string  `json:"best_time"`
	Tags             []string `json:"tags"`
	IsFavorited      bool     `json:"is_favorited"`
	DistanceMeters   *float64 `json:"distance_meters,omitempty"`
}

type SpotQuery struct {
	Latitude  *float64
	Longitude *float64
	Radius    float64
	Keyword   string
	Page      int
	PageSize  int
}

type SpotList struct {
	Items    []Spot `json:"items"`
	Page     int    `json:"page"`
	PageSize int    `json:"page_size"`
	Total    int64  `json:"total"`
}

type SpotService struct {
	database *pgxpool.Pool
}

func NewSpotService(database *pgxpool.Pool) *SpotService {
	return &SpotService{database: database}
}

const spotSearch = `
	WITH spots AS (
		SELECT id, name, description, latitude, longitude, coordinate_system,
			address, cover_url, best_time, tags, created_at,
			CASE WHEN $1 THEN 6371000 * acos(LEAST(1, GREATEST(-1,
				cos(radians($2)) * cos(radians(latitude::double precision)) *
				cos(radians(longitude::double precision) - radians($3)) +
				sin(radians($2)) * sin(radians(latitude::double precision))
			))) END AS distance_meters
		FROM shooting_spots
		WHERE status = 1 AND ($4 = '' OR name ILIKE '%' || $4 || '%' OR description ILIKE '%' || $4 || '%')
	)
`

func (s *SpotService) List(ctx context.Context, query SpotQuery) (SpotList, error) {
	nearby := query.Latitude != nil
	var latitude, longitude float64
	if nearby {
		latitude, longitude = *query.Latitude, *query.Longitude
	}
	args := []any{nearby, latitude, longitude, query.Keyword, query.Radius}
	result := SpotList{Items: []Spot{}, Page: query.Page, PageSize: query.PageSize}
	if err := s.database.QueryRow(ctx, spotSearch+`
		SELECT count(*) FROM spots WHERE NOT $1 OR distance_meters <= $5
	`, args...).Scan(&result.Total); err != nil {
		return SpotList{}, err
	}
	rows, err := s.database.Query(ctx, spotSearch+`
		SELECT id, name, description, latitude, longitude, coordinate_system,
			address, cover_url, best_time, tags, distance_meters
		FROM spots
		WHERE NOT $1 OR distance_meters <= $5
		ORDER BY CASE WHEN $1 THEN distance_meters END NULLS LAST, created_at DESC, id
		LIMIT $6 OFFSET $7
	`, append(args, query.PageSize, (query.Page-1)*query.PageSize)...)
	if err != nil {
		return SpotList{}, err
	}
	defer rows.Close()
	for rows.Next() {
		var spot Spot
		if err := rows.Scan(
			&spot.ID, &spot.Name, &spot.Description, &spot.Latitude, &spot.Longitude,
			&spot.CoordinateSystem, &spot.Address, &spot.CoverURL, &spot.BestTime,
			&spot.Tags, &spot.DistanceMeters,
		); err != nil {
			return SpotList{}, err
		}
		result.Items = append(result.Items, spot)
	}
	return result, rows.Err()
}

func (s *SpotService) Get(ctx context.Context, spotID string) (Spot, error) {
	var spot Spot
	err := s.database.QueryRow(ctx, `
		SELECT id, name, description, latitude, longitude, coordinate_system,
			address, cover_url, best_time, tags
		FROM shooting_spots
		WHERE id = $1 AND status = 1
	`, spotID).Scan(
		&spot.ID, &spot.Name, &spot.Description, &spot.Latitude, &spot.Longitude,
		&spot.CoordinateSystem, &spot.Address, &spot.CoverURL, &spot.BestTime, &spot.Tags,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return Spot{}, ErrSpotNotFound
	}
	return spot, err
}
