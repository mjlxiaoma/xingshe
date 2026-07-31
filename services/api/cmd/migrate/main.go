package main

import (
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strings"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
	_ "github.com/golang-migrate/migrate/v4/source/file"
)

func main() {
	if err := run(os.Args[1:]); err != nil {
		slog.Error("migration failed", "error", err)
		os.Exit(1)
	}
}

func run(args []string) error {
	if len(args) != 1 || (args[0] != "up" && args[0] != "down") {
		return errors.New("usage: go run ./cmd/migrate up|down")
	}
	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		return errors.New("DATABASE_URL is required")
	}
	sourceURL := strings.TrimSpace(os.Getenv("MIGRATIONS_URL"))
	if sourceURL == "" {
		sourceURL = "file://migrations"
	}

	migration, err := migrate.New(sourceURL, pgxMigrationURL(databaseURL))
	if err != nil {
		return fmt.Errorf("open migrations: %w", err)
	}
	defer migration.Close()

	if args[0] == "up" {
		err = migration.Up()
	} else {
		err = migration.Steps(-1)
	}
	if errors.Is(err, migrate.ErrNoChange) {
		return nil
	}
	return err
}

func pgxMigrationURL(databaseURL string) string {
	databaseURL = strings.TrimSpace(databaseURL)
	if rest, ok := strings.CutPrefix(databaseURL, "postgres://"); ok {
		return "pgx5://" + rest
	}
	if rest, ok := strings.CutPrefix(databaseURL, "postgresql://"); ok {
		return "pgx5://" + rest
	}
	return databaseURL
}
