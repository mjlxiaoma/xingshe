package main

import "testing"

func TestPGXMigrationURL(t *testing.T) {
	tests := map[string]string{
		"postgres://user:pass@localhost/db":   "pgx5://user:pass@localhost/db",
		"postgresql://user:pass@localhost/db": "pgx5://user:pass@localhost/db",
		"pgx5://user:pass@localhost/db":       "pgx5://user:pass@localhost/db",
	}
	for input, want := range tests {
		if got := pgxMigrationURL(input); got != want {
			t.Errorf("pgxMigrationURL(%q) = %q, want %q", input, got, want)
		}
	}
}
