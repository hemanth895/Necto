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

type HospitalHandler struct {
	cfg  *config.Config
	pool *pgxpool.Pool
}

func NewHospitalHandler(cfg *config.Config, pool *pgxpool.Pool) *HospitalHandler {
	return &HospitalHandler{cfg: cfg, pool: pool}
}

func (h *HospitalHandler) Routes() chi.Router {
	r := chi.NewRouter()
	r.Use(middleware.RequireAuth(h.cfg.JWTSecret))
	r.Use(middleware.RequireRole("hospital"))
	r.Get("/profile", h.GetProfile)
	r.Post("/profile", h.CreateProfile)
	r.Get("/dashboard", h.Dashboard)
	r.Post("/shifts", h.PostShift)
	r.Get("/shifts/{id}/available-staff", h.ViewAvailableStaff)
	return r
}

func (h *HospitalHandler) GetProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	profile, err := database.GetHospitalProfileByUserID(r.Context(), h.pool, userID)
	if err != nil || profile == nil {
		JSON(w, http.StatusOK, map[string]interface{}{"has_profile": false})
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{
		"has_profile": true, "hospital_name": profile.HospitalName, "verified": profile.Verified,
	})
}

func (h *HospitalHandler) CreateProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	existing, _ := database.GetHospitalProfileByUserID(r.Context(), h.pool, userID)
	if existing != nil {
		Error(w, http.StatusBadRequest, "profile already exists")
		return
	}
	var req struct {
		HospitalName   string `json:"hospital_name"`
		Address        string `json:"address"`
		Telephone      string `json:"telephone"`
		ContactNumber  string `json:"contact_number"`
		Pincode        string `json:"pincode"`
		HospitalImage  string `json:"hospital_image"`
		Consent        bool   `json:"consent"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.HospitalName == "" || req.Address == "" || req.Telephone == "" || req.ContactNumber == "" || req.Pincode == "" {
		Error(w, http.StatusBadRequest, "all fields are mandatory")
		return
	}
	if !req.Consent {
		Error(w, http.StatusBadRequest, "you must agree to terms and privacy policy")
		return
	}
	id, err := database.CreateHospitalProfile(r.Context(), h.pool, userID, req.HospitalName, req.Address, req.Telephone, req.ContactNumber, req.Pincode, req.HospitalImage)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to save profile")
		return
	}
	JSON(w, http.StatusCreated, map[string]interface{}{"id": id, "message": "profile created"})
}

func (h *HospitalHandler) Dashboard(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	profile, err := database.GetHospitalProfileByUserID(r.Context(), h.pool, userID)
	if err != nil || profile == nil {
		JSON(w, http.StatusOK, map[string]interface{}{"has_profile": false})
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{
		"has_profile": true, "hospital_name": profile.HospitalName, "verified": profile.Verified,
	})
}

func (h *HospitalHandler) PostShift(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	profile, err := database.GetHospitalProfileByUserID(r.Context(), h.pool, userID)
	if err != nil || profile == nil {
		Error(w, http.StatusBadRequest, "complete hospital profile first")
		return
	}
	if profile.Verified != "yes" {
		Error(w, http.StatusForbidden, "hospital verification pending")
		return
	}
	var req struct {
		ShiftDate       string  `json:"shift_date"`
		StartTime       string  `json:"start_time"`
		EndTime         string  `json:"end_time"`
		DegreeRequired  string  `json:"degree_required"`
		StreamRequired  string  `json:"stream_required"`
		RoleRequired    string  `json:"role_required"`
		Latitude        string  `json:"latitude"`
		Longitude       string  `json:"longitude"`
		PaymentAmount   float64 `json:"payment_amount"`
		PaymentType     string  `json:"payment_type"`
		Notes           string  `json:"notes"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.ShiftDate == "" || req.StartTime == "" || req.EndTime == "" || req.DegreeRequired == "" || req.StreamRequired == "" || req.RoleRequired == "" || req.Latitude == "" || req.Longitude == "" || req.PaymentAmount <= 0 {
		Error(w, http.StatusBadRequest, "all mandatory fields are required")
		return
	}
	id, err := database.CreateHospitalShift(r.Context(), h.pool, userID, profile.HospitalName, req.DegreeRequired, req.StreamRequired, req.RoleRequired, req.ShiftDate, req.StartTime, req.EndTime, req.Latitude, req.Longitude, req.PaymentAmount, req.PaymentType, req.Notes)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to post shift")
		return
	}
	JSON(w, http.StatusCreated, map[string]interface{}{"id": id, "message": "shift posted"})
}

func (h *HospitalHandler) ViewAvailableStaff(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	shiftIDStr := chi.URLParam(r, "id")
	shiftID, _ := strconv.ParseInt(shiftIDStr, 10, 64)
	if shiftID <= 0 {
		Error(w, http.StatusBadRequest, "invalid shift id")
		return
	}
	degree, stream, shiftDate, startTime, endTime, lat, lng, status, err := database.GetHospitalShift(r.Context(), h.pool, shiftID, userID)
	if err != nil || status != "open" {
		Error(w, http.StatusNotFound, "shift not available")
		return
	}
	list, err := database.GetAvailableStaffForShift(r.Context(), h.pool, lat, lng, degree, stream, shiftDate, startTime, endTime, 20)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to fetch staff")
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{"shift_id": shiftID, "staff": list})
}
