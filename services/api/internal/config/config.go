package config

import "os"

type Config struct {
	Address string
}

func Load() Config {
	port := os.Getenv("API_PORT")
	if port == "" {
		port = "8080"
	}
	return Config{Address: ":" + port}
}
