package handlers

import (
	"net/http"
	"strconv"

	"necto/backend/internal/config"
	"necto/backend/internal/database"
	"necto/backend/internal/middleware"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type AdminHandler struct {
	cfg  *config.Config
	pool *pgxpool.Pool
}

func NewAdminHandler(cfg *config.Config, pool *pgxpool.Pool) *AdminHandler {
	return &AdminHandler{cfg: cfg, pool: pool}
}

func (h *AdminHandler) Routes() chi.Router {
	r := chi.NewRouter()
	r.Use(middleware.RequireAuth(h.cfg.JWTSecret))
	r.Use(middleware.RequireRole("admin"))
	r.Get("/dashboard", h.Dashboard)
	r.Get("/staff/pending", h.ListPendingStaff)
	r.Get("/hospital/pending", h.ListPendingHospitals)
	r.Post("/staff/{id}/verify", h.VerifyStaff)
	r.Post("/hospital/{id}/verify", h.VerifyHospital)
	return r
}

func (h *AdminHandler) ListPendingStaff(w http.ResponseWriter, r *http.Request) {
	list, err := database.AdminListPendingStaff(r.Context(), h.pool)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load")
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{"staff": list})
}

func (h *AdminHandler) ListPendingHospitals(w http.ResponseWriter, r *http.Request) {
	list, err := database.AdminListPendingHospitals(r.Context(), h.pool)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load")
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{"hospitals": list})
}

func (h *AdminHandler) Dashboard(w http.ResponseWriter, r *http.Request) {
	staffCount, hospitalCount, pendingStaff, pendingHospital, err := database.AdminGetCounts(r.Context(), h.pool)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load counts")
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{
		"staff_count":         staffCount,
		"hospital_count":     hospitalCount,
		"pending_staff":      pendingStaff,
		"pending_hospital":   pendingHospital,
	})
}

func (h *AdminHandler) VerifyStaff(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, _ := strconv.ParseInt(idStr, 10, 64)
	if id <= 0 {
		Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	var req struct {
		Approve          bool   `json:"approve"`
		RejectionReason  string `json:"rejection_reason"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if !req.Approve && req.RejectionReason == "" {
		Error(w, http.StatusBadRequest, "rejection reason required")
		return
	}
	if err := database.AdminVerifyStaff(r.Context(), h.pool, id, req.Approve, req.RejectionReason); err != nil {
		Error(w, http.StatusInternalServerError, "failed to update")
		return
	}
	JSON(w, http.StatusOK, map[string]string{"message": "updated"})
}

func (h *AdminHandler) VerifyHospital(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, _ := strconv.ParseInt(idStr, 10, 64)
	if id <= 0 {
		Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	var req struct {
		Approve          bool   `json:"approve"`
		RejectionReason  string `json:"rejection_reason"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if !req.Approve && req.RejectionReason == "" {
		Error(w, http.StatusBadRequest, "rejection reason required")
		return
	}
	if err := database.AdminVerifyHospital(r.Context(), h.pool, id, req.Approve, req.RejectionReason); err != nil {
		Error(w, http.StatusInternalServerError, "failed to update")
		return
	}
	JSON(w, http.StatusOK, map[string]string{"message": "updated"})
}
