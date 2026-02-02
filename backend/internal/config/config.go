package config

import (
	"os"
)

type Config struct {
	ServerPort   string
	DBHost      string
	DBPort      string
	DBUser      string
	DBPassword  string
	DBName      string
	DBSSLMode   string
	JWTSecret   string
	UploadPath  string
}

func Load() *Config {
	return &Config{
		ServerPort:  getEnv("PORT", "8080"),
		DBHost:      getEnv("DB_HOST", "localhost"),
		DBPort:      getEnv("DB_PORT", "5432"),
		DBUser:      getEnv("DB_USER", "necto"),
		DBPassword:  getEnv("DB_PASSWORD", "necto"),
		DBName:      getEnv("DB_NAME", "necto_db"),
		DBSSLMode:   getEnv("DB_SSLMODE", "disable"),
		JWTSecret:   getEnv("JWT_SECRET", "necto-jwt-secret-change-in-production"),
		UploadPath:  getEnv("UPLOAD_PATH", "./uploads"),
	}
}

func (c *Config) DSN() string {
	return "postgres://" + c.DBUser + ":" + c.DBPassword + "@" + c.DBHost + ":" + c.DBPort + "/" + c.DBName + "?sslmode=" + c.DBSSLMode
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
