package main

import (
	"log"
	"net/http"

	"necto/backend/internal/config"
	"necto/backend/internal/database"
	"necto/backend/internal/handlers"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

func main() {
	cfg := config.Load()
	pool, err := database.NewPool(cfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()

	authH := handlers.NewAuthHandler(cfg, pool)
	hospitalH := handlers.NewHospitalHandler(cfg, pool)
	staffH := handlers.NewStaffHandler(cfg, pool)
	adminH := handlers.NewAdminHandler(cfg, pool)

	r := chi.NewRouter()
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RealIP)

	r.Mount("/api/auth", authH.Routes())
	r.Mount("/api/hospital", hospitalH.Routes())
	r.Mount("/api/staff", staffH.Routes())
	r.Mount("/api/admin", adminH.Routes())

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status":"ok"}`))
	})

	addr := ":" + cfg.ServerPort
	log.Printf("listening on %s", addr)
	if err := http.ListenAndServe(addr, r); err != nil {
		log.Fatalf("serve: %v", err)
	}
}
