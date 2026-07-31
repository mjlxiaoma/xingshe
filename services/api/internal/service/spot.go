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
	UserID    string
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
			address, cover_url, best_time, tags,
			EXISTS (SELECT 1 FROM user_favorite_spots favorites WHERE favorites.user_id = $6 AND favorites.spot_id = spots.id),
			distance_meters
		FROM spots
		WHERE NOT $1 OR distance_meters <= $5
		ORDER BY CASE WHEN $1 THEN distance_meters END NULLS LAST, created_at DESC, id
		LIMIT $7 OFFSET $8
	`, append(args, optionalID(query.UserID), query.PageSize, (query.Page-1)*query.PageSize)...)
	if err != nil {
		return SpotList{}, err
	}
	defer rows.Close()
	for rows.Next() {
		var spot Spot
		if err := rows.Scan(
			&spot.ID, &spot.Name, &spot.Description, &spot.Latitude, &spot.Longitude,
			&spot.CoordinateSystem, &spot.Address, &spot.CoverURL, &spot.BestTime,
			&spot.Tags, &spot.IsFavorited, &spot.DistanceMeters,
		); err != nil {
			return SpotList{}, err
		}
		result.Items = append(result.Items, spot)
	}
	return result, rows.Err()
}

func (s *SpotService) Get(ctx context.Context, spotID, userID string) (Spot, error) {
	var spot Spot
	err := s.database.QueryRow(ctx, `
		SELECT id, name, description, latitude, longitude, coordinate_system,
			address, cover_url, best_time, tags,
			EXISTS (SELECT 1 FROM user_favorite_spots favorites WHERE favorites.user_id = $2 AND favorites.spot_id = shooting_spots.id)
		FROM shooting_spots
		WHERE id = $1 AND status = 1
	`, spotID, optionalID(userID)).Scan(
		&spot.ID, &spot.Name, &spot.Description, &spot.Latitude, &spot.Longitude,
		&spot.CoordinateSystem, &spot.Address, &spot.CoverURL, &spot.BestTime, &spot.Tags, &spot.IsFavorited,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return Spot{}, ErrSpotNotFound
	}
	return spot, err
}

func (s *SpotService) Favorite(ctx context.Context, userID, spotID string) error {
	var exists bool
	err := s.database.QueryRow(ctx, `
		WITH spot AS (
			SELECT id FROM shooting_spots WHERE id = $2 AND status = 1
		), inserted AS (
			INSERT INTO user_favorite_spots (user_id, spot_id)
			SELECT $1, id FROM spot
			ON CONFLICT (user_id, spot_id) DO NOTHING
		)
		SELECT EXISTS (SELECT 1 FROM spot)
	`, userID, spotID).Scan(&exists)
	if err != nil {
		return err
	}
	if !exists {
		return ErrSpotNotFound
	}
	return nil
}

func (s *SpotService) Unfavorite(ctx context.Context, userID, spotID string) error {
	_, err := s.database.Exec(ctx, `
		DELETE FROM user_favorite_spots WHERE user_id = $1 AND spot_id = $2
	`, userID, spotID)
	return err
}

func (s *SpotService) Favorites(ctx context.Context, userID string) ([]Spot, error) {
	rows, err := s.database.Query(ctx, `
		SELECT spots.id, spots.name, spots.description, spots.latitude, spots.longitude,
			spots.coordinate_system, spots.address, spots.cover_url, spots.best_time, spots.tags
		FROM user_favorite_spots favorites
		JOIN shooting_spots spots ON spots.id = favorites.spot_id AND spots.status = 1
		WHERE favorites.user_id = $1
		ORDER BY favorites.created_at DESC, spots.id
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	spots := []Spot{}
	for rows.Next() {
		spot := Spot{IsFavorited: true}
		if err := rows.Scan(
			&spot.ID, &spot.Name, &spot.Description, &spot.Latitude, &spot.Longitude,
			&spot.CoordinateSystem, &spot.Address, &spot.CoverURL, &spot.BestTime, &spot.Tags,
		); err != nil {
			return nil, err
		}
		spots = append(spots, spot)
	}
	return spots, rows.Err()
}

func optionalID(value string) any {
	if value == "" {
		return nil
	}
	return value
}
