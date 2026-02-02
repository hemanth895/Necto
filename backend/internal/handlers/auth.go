package handlers

import (
	"net/http"

	"necto/backend/internal/auth"
	"necto/backend/internal/config"
	"necto/backend/internal/database"

	"github.com/go-chi/chi/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	cfg  *config.Config
	pool *pgxpool.Pool
}

func NewAuthHandler(cfg *config.Config, pool *pgxpool.Pool) *AuthHandler {
	return &AuthHandler{cfg: cfg, pool: pool}
}

func (h *AuthHandler) Routes() chi.Router {
	r := chi.NewRouter()
	r.Post("/login", h.Login)
	r.Post("/register", h.Register)
	r.Post("/forgot-password", h.ForgotPassword)
	r.Post("/reset-password", h.ResetPassword)
	return r
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginResponse struct {
	Token string `json:"token"`
	Role  string `json:"role"`
	ID    int64  `json:"id"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	req.Email = trim(req.Email)
	if req.Email == "" || req.Password == "" {
		Error(w, http.StatusBadRequest, "email and password are required")
		return
	}

	user, err := database.GetUserByEmail(r.Context(), h.pool, req.Email)
	if err != nil || user.ID == 0 {
		Error(w, http.StatusUnauthorized, "invalid email or password")
		return
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		Error(w, http.StatusUnauthorized, "invalid email or password")
		return
	}

	token, err := auth.CreateToken(user.ID, user.Role, user.Email, h.cfg.JWTSecret)
	if err != nil {
		Error(w, http.StatusInternalServerError, "failed to create token")
		return
	}
	JSON(w, http.StatusOK, LoginResponse{Token: token, Role: user.Role, ID: user.ID})
}

type RegisterRequest struct {
	Name         string `json:"name"`
	Email        string `json:"email"`
	Password     string `json:"password"`
	Role         string `json:"role"`
	AgreeTerms   bool   `json:"agree_terms"`
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	req.Name = trim(req.Name)
	req.Email = trim(req.Email)
	if req.Name == "" || req.Email == "" || req.Password == "" {
		Error(w, http.StatusBadRequest, "all fields are required")
		return
	}
	if req.Role != "hospital" && req.Role != "staff" {
		Error(w, http.StatusBadRequest, "please select account type (hospital or staff)")
		return
	}
	if !req.AgreeTerms {
		Error(w, http.StatusBadRequest, "you must agree to terms and privacy policy")
		return
	}

	exists, _ := database.UserExistsByEmail(r.Context(), h.pool, req.Email)
	if exists {
		Error(w, http.StatusBadRequest, "email already registered")
		return
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		Error(w, http.StatusInternalServerError, "registration failed")
		return
	}

	id, err := database.CreateUser(r.Context(), h.pool, req.Name, req.Email, string(hash), req.Role)
	if err != nil {
		Error(w, http.StatusInternalServerError, "registration failed")
		return
	}
	JSON(w, http.StatusCreated, map[string]interface{}{"id": id, "message": "account created"})
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

func (h *AuthHandler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var req ForgotPasswordRequest
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	req.Email = trim(req.Email)
	if req.Email == "" {
		Error(w, http.StatusBadRequest, "email is required")
		return
	}
	exists, _ := database.UserExistsByEmail(r.Context(), h.pool, req.Email)
	if !exists {
		Error(w, http.StatusBadRequest, "email not found")
		return
	}
	JSON(w, http.StatusOK, map[string]string{"message": "ok", "email": req.Email})
}

type ResetPasswordRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var req ResetPasswordRequest
	if err := jsonDecode(r, &req); err != nil {
		Error(w, http.StatusBadRequest, "invalid request body")
		return
	}
	req.Email = trim(req.Email)
	if req.Email == "" {
		Error(w, http.StatusBadRequest, "invalid email")
		return
	}
	if len(req.Password) < 6 {
		Error(w, http.StatusBadRequest, "password must be at least 6 characters")
		return
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		Error(w, http.StatusInternalServerError, "reset failed")
		return
	}
	err = database.UpdateUserPassword(r.Context(), h.pool, req.Email, string(hash))
	if err != nil {
		Error(w, http.StatusBadRequest, "password reset failed or email not found")
		return
	}
	JSON(w, http.StatusOK, map[string]string{"message": "password reset successful"})
}
