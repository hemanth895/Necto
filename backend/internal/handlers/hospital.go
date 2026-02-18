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
	r.Get("/shifts", h.ListShifts)
	r.Post("/shifts", h.PostShift)
	r.Get("/shifts/{id}/available-staff", h.ViewAvailableStaff)
	r.Post("/shifts/{id}/request", h.SendRequest)
	r.Get("/requests", h.ListRequests)
	r.Get("/booked-shifts", h.ListBookedShifts)
	r.Get("/notifications", h.ListNotifications)
	r.Post("/notifications/{id}/read", h.MarkNotificationRead)
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

func (h *HospitalHandler) ListShifts(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	list, err := database.GetHospitalShiftsByUserID(r.Context(), h.pool, userID)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load shifts")
		return
	}
	out := make([]map[string]interface{}, 0, len(list))
	for _, row := range list {
		out = append(out, map[string]interface{}{
			"id": row.ID, "shift_date": row.ShiftDate, "start_time": row.StartTime, "end_time": row.EndTime,
			"role_required": row.RoleRequired, "degree_required": row.Degree, "stream_required": row.Stream,
			"status": row.Status, "payment_amount": row.PaymentAmount, "payment_type": row.PaymentType, "created_at": row.CreatedAt,
		})
	}
	JSON(w, http.StatusOK, map[string]interface{}{"shifts": out})
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
	out := make([]map[string]interface{}, 0, len(list))
	for _, row := range list {
		out = append(out, map[string]interface{}{
			"availability_id": row.AvailabilityID, "staff_id": row.StaffID, "full_name": row.FullName,
			"degree": row.Degree, "specialization": row.Specialization, "experience_years": row.ExperienceYears,
			"current_institution": row.CurrentInstitution, "working_role": row.WorkingRole,
			"latitude": row.Latitude, "longitude": row.Longitude, "distance": row.Distance,
			"profile_photo": row.ProfilePhoto,
		})
	}
	JSON(w, http.StatusOK, map[string]interface{}{"shift_id": shiftID, "staff": out})
}

func (h *HospitalHandler) SendRequest(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	shiftIDStr := chi.URLParam(r, "id")
	shiftID, _ := strconv.ParseInt(shiftIDStr, 10, 64)
	if shiftID <= 0 {
		Error(w, http.StatusBadRequest, "invalid shift id")
		return
	}
	var req struct {
		StaffID        int64 `json:"staff_id"`
		AvailabilityID int64 `json:"availability_id"`
	}
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.StaffID <= 0 || req.AvailabilityID <= 0 {
		Error(w, http.StatusBadRequest, "staff_id and availability_id are required")
		return
	}
	degree, stream, shiftDate, startTime, endTime, lat, lng, status, err := database.GetHospitalShift(r.Context(), h.pool, shiftID, userID)
	if err != nil || status != "open" {
		Error(w, http.StatusNotFound, "shift not available")
		return
	}
	hasActive, _ := database.ShiftHasActiveRequest(r.Context(), h.pool, shiftID)
	if hasActive {
		Error(w, http.StatusBadRequest, "this shift already has a pending or accepted request")
		return
	}
	list, err := database.GetAvailableStaffForShift(r.Context(), h.pool, lat, lng, degree, stream, shiftDate, startTime, endTime, 20)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to validate staff")
		return
	}
	var distanceKm float64
	var found bool
	for _, s := range list {
		if s.StaffID == req.StaffID && s.AvailabilityID == req.AvailabilityID {
			distanceKm = s.Distance
			found = true
			break
		}
	}
	if !found {
		Error(w, http.StatusBadRequest, "staff or availability not in available list for this shift")
		return
	}
	requestID, err := database.CreateShiftRequest(r.Context(), h.pool, shiftID, req.AvailabilityID, req.StaffID, userID, distanceKm)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to send request")
		return
	}
	_ = database.CreateStaffNotification(r.Context(), h.pool, req.StaffID, "New shift request", "A hospital sent you a shift request. Check your requests.")
	JSON(w, http.StatusCreated, map[string]interface{}{"id": requestID, "message": "request sent"})
}

func (h *HospitalHandler) ListRequests(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	list, err := database.GetHospitalRequests(r.Context(), h.pool, userID)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load requests")
		return
	}
	out := make([]map[string]interface{}, 0, len(list))
	for _, row := range list {
		dist := 0.0
		if row.DistanceKm != nil {
			dist = *row.DistanceKm
		}
		out = append(out, map[string]interface{}{
			"request_id": row.RequestID, "shift_id": row.ShiftID, "shift_date": row.ShiftDate,
			"start_time": row.StartTime, "end_time": row.EndTime, "role_required": row.RoleRequired,
			"payment_amount": row.PaymentAmount, "status": row.Status, "staff_id": row.StaffID,
			"staff_name": row.StaffName, "degree": row.Degree, "stream": row.Stream,
			"distance_km": dist, "created_at": row.CreatedAt,
		})
	}
	JSON(w, http.StatusOK, map[string]interface{}{"requests": out})
}

func (h *HospitalHandler) ListBookedShifts(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	list, err := database.GetHospitalBookedShifts(r.Context(), h.pool, userID)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load booked shifts")
		return
	}
	out := make([]map[string]interface{}, 0, len(list))
	for _, row := range list {
		out = append(out, map[string]interface{}{
			"request_id": row.RequestID, "shift_id": row.ShiftID, "shift_date": row.ShiftDate,
			"start_time": row.StartTime, "end_time": row.EndTime, "role_required": row.RoleRequired,
			"payment_amount": row.PaymentAmount, "staff_id": row.StaffID, "staff_name": row.StaffName,
			"staff_mobile": row.StaffMobile, "staff_email": row.StaffEmail, "staff_address": row.StaffAddress,
			"degree": row.Degree, "stream": row.Stream,
		})
	}
	JSON(w, http.StatusOK, map[string]interface{}{"booked_shifts": out})
}

func (h *HospitalHandler) ListNotifications(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	list, err := database.GetHospitalNotifications(r.Context(), h.pool, userID)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to load notifications")
		return
	}
	out := make([]map[string]interface{}, 0, len(list))
	for _, row := range list {
		out = append(out, map[string]interface{}{
			"id": row.ID, "title": row.Title, "message": row.Message, "is_read": row.IsRead, "created_at": row.CreatedAt,
		})
	}
	JSON(w, http.StatusOK, map[string]interface{}{"notifications": out})
}

func (h *HospitalHandler) MarkNotificationRead(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	idStr := chi.URLParam(r, "id")
	notificationID, _ := strconv.ParseInt(idStr, 10, 64)
	if notificationID <= 0 {
		Error(w, http.StatusBadRequest, "invalid notification id")
		return
	}
	if err := database.MarkHospitalNotificationRead(r.Context(), h.pool, notificationID, userID); err != nil {
		Error(w, http.StatusInternalServerError, "failed to update")
		return
	}
	JSON(w, http.StatusOK, map[string]interface{}{"message": "updated"})
}
