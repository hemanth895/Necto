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

type StaffHandler struct {
	cfg  *config.Config
	pool *pgxpool.Pool
}

func NewStaffHandler(cfg *config.Config, pool *pgxpool.Pool) *StaffHandler {
	return &StaffHandler{cfg: cfg, pool: pool}
}

func (h *StaffHandler) Routes() chi.Router {
	r := chi.NewRouter()
	r.Use(middleware.RequireAuth(h.cfg.JWTSecret))
	r.Use(middleware.RequireRole("staff"))
	r.Get("/profile", h.GetProfile)
	r.Post("/profile", h.CreateProfile)
	r.Get("/dashboard", h.Dashboard)
	r.Post("/availability", h.PostAvailability)
	return r
}

func (h *StaffHandler) GetProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_, verified, err := database.GetStaffProfileByUserID(r.Context(), h.pool, userID)
	if err != nil {
		JSON(w, http.StatusOK, map[string]interface{}{"has_profile": false})
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{"has_profile": true, "verified": verified})
}

func (h *StaffHandler) CreateProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_, _, err := database.GetStaffProfileByUserID(r.Context(), h.pool, userID)
	if err == nil {
		Error(w, http.StatusBadRequest, "profile already exists")
		return
	}
	var req struct {
		FullName           string  `json:"full_name"`
		Age                int     `json:"age"`
		DOB                string  `json:"dob"`
		Gender             string  `json:"gender"`
		Address            string  `json:"address"`
		Email              string  `json:"email"`
		Mobile             string  `json:"mobile"`
		EmergencyMobile    string  `json:"emergency_mobile"`
		Degree             string  `json:"degree"`
		Stream             string  `json:"stream"`
		OtherStream        *string `json:"other_stream"`
		College            string  `json:"college"`
		ExperienceYears    int     `json:"experience_years"`
		CurrentInstitution string  `json:"current_institution"`
		WorkingRole        string  `json:"working_role"`
		WillingRoles       string  `json:"willing_roles"`
		PreferredLocation  string  `json:"preferred_location"`
		ProfilePhoto       *string `json:"profile_photo"`
		Consent            string  `json:"consent"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.FullName == "" || req.Mobile == "" || req.EmergencyMobile == "" {
		Error(w, http.StatusBadRequest, "all fields required")
		return
	}
	if req.Mobile == req.EmergencyMobile {
		Error(w, http.StatusBadRequest, "emergency contact must be different from mobile")
		return
	}
	p := database.CreateStaffProfileParams{
		UserID: userID, FullName: req.FullName, Age: req.Age, DOB: req.DOB, Gender: req.Gender, Address: req.Address,
		Email: req.Email, Mobile: req.Mobile, EmergencyMobile: req.EmergencyMobile, Degree: req.Degree, Stream: req.Stream,
		OtherStream: req.OtherStream, College: req.College, ExperienceYears: req.ExperienceYears, CurrentInstitution: req.CurrentInstitution,
		WorkingRole: req.WorkingRole, WillingRoles: req.WillingRoles, PreferredLocation: req.PreferredLocation,
		ProfilePhoto: req.ProfilePhoto, Consent: req.Consent,
	}
	id, err := database.CreateStaffProfile(r.Context(), h.pool, p)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to save profile")
		return
	}
	JSON(w, http.StatusCreated, map[string]interface{}{"id": id, "message": "profile created"})
}

func (h *StaffHandler) Dashboard(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_, verified, err := database.GetStaffProfileByUserID(r.Context(), h.pool, userID)
	if err != nil {
		JSON(w, http.StatusOK, map[string]interface{}{"has_profile": false})
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{"has_profile": true, "verified": verified})
}

func (h *StaffHandler) PostAvailability(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	_, verified, err := database.GetStaffProfileByUserID(r.Context(), h.pool, userID)
	if err != nil {
		Error(w, http.StatusBadRequest, "complete staff profile first")
		return
	}
	if verified != "yes" {
		Error(w, http.StatusForbidden, "profile not verified")
		return
	}
	var req struct {
		District   string  `json:"district"`
		Taluka     string  `json:"taluka"`
		WorkDate   string  `json:"work_date"`
		StartTime  string  `json:"start_time"`
		EndTime    string  `json:"end_time"`
		Latitude   float64 `json:"latitude"`
		Longitude  float64 `json:"longitude"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.District == "" || req.Taluka == "" || req.WorkDate == "" || req.StartTime == "" || req.EndTime == "" {
		Error(w, http.StatusBadRequest, "all fields including location are required")
		return
	}
	_, err = database.CreateStaffAvailability(r.Context(), h.pool, userID, "Karnataka", req.District, req.Taluka, req.WorkDate, req.StartTime, req.EndTime, req.Latitude, req.Longitude)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to post availability")
		return
	}
	JSON(w, http.StatusCreated, map[string]interface{}{"message": "availability posted"})
}
