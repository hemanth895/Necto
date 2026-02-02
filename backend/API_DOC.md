# Necto Backend API Reference

Base URL: `http://localhost:8080`

All endpoints expecting JSON require header: `Content-Type: application/json`.
Authenticated endpoints require header: `Authorization: Bearer <JWT>` (obtain from `/api/auth/login`).

---

## Health
- Method: GET
- Path: `/health`
- Auth: none
- Response: `{"status":"ok"}`

Example:
```
curl -i http://localhost:8080/health
```

---

## Auth

### POST /api/auth/register
- Registers a new user (role: `hospital` or `staff`).
- Body:
```json
{ "name":"...", "email":"...", "password":"...", "role":"hospital|staff", "agree_terms": true }
```
- Response: 201 created
```json
{ "id": 123, "message":"account created" }
```

### POST /api/auth/login
- Body:
```json
{ "email": "...", "password": "..." }
```
- Response: 200
```json
{ "token":"<JWT>", "role":"staff|hospital|admin", "id": 123 }
```
- Use `token` for `Authorization: Bearer <token>` on protected routes.

### POST /api/auth/forgot-password
- Body: `{ "email":"..." }`
- Response: 200 `{ "message":"ok", "email":"..." }`

### POST /api/auth/reset-password
- Body: `{ "email":"...", "password":"newpass" }`
- Response: 200 `{ "message":"password reset successful" }`

---

## Hospital Endpoints (role: hospital)
All hospital endpoints require authentication and role `hospital`.

### GET /api/hospital/profile
- Returns whether profile exists and data if available.
- Response example:
```json
{ "has_profile": true, "hospital_name":"...", "verified":"yes|no" }
```

### POST /api/hospital/profile
- Create hospital profile.
- Body:
```json
{
  "hospital_name":"...",
  "address":"...",
  "telephone":"...",
  "contact_number":"...",
  "pincode":"...",
  "hospital_image":"<url-or-empty>",
  "consent": true
}
```
- Response: 201 `{ "id": <id>, "message":"profile created" }`

### GET /api/hospital/dashboard
- Returns counts and verification info for the authenticated hospital.

### POST /api/hospital/shifts
- Post a shift (hospital must be verified by admin `verified == "yes"`).
- Body:
```json
{
  "shift_date":"YYYY-MM-DD",
  "start_time":"HH:MM",
  "end_time":"HH:MM",
  "degree_required":"...",
  "stream_required":"...",
  "role_required":"...",
  "latitude":"<string>",
  "longitude":"<string>",
  "payment_amount": 500.0,
  "payment_type":"per_shift|per_hour",
  "notes":"..."
}
```
- Response: 201 `{ "id": <shift_id>, "message":"shift posted" }`

### GET /api/hospital/shifts/{id}/available-staff
- Path param: `id` = shift id
- Returns a list of available staff for the given shift (requires hospital ownership of shift).
- Response: `{ "shift_id": <id>, "staff": [ ... ] }`

---

## Staff Endpoints (role: staff)
All staff endpoints require authentication and role `staff`.

### GET /api/staff/profile
- Response: `{ "has_profile": true/false, "verified":"yes|no" }

### POST /api/staff/profile
- Create staff profile.
- Body (example):
```json
{
  "full_name":"...",
  "age": 30,
  "dob":"YYYY-MM-DD",
  "gender":"...",
  "address":"...",
  "email":"...",
  "mobile":"...",
  "emergency_mobile":"...",
  "degree":"...",
  "stream":"...",
  "other_stream": null,
  "college":"...",
  "experience_years": 2,
  "current_institution":"...",
  "working_role":"...",
  "willing_roles":"...",
  "preferred_location":"...",
  "profile_photo": null,
  "consent":"yes"
}
```
- Response: 201 `{ "id": <id>, "message":"profile created" }`

### GET /api/staff/dashboard
- Returns `has_profile` and `verified` status.

### POST /api/staff/availability
- Staff must be verified by admin to post availability.
- Body:
```json
{
  "district":"...",
  "taluka":"...",
  "work_date":"YYYY-MM-DD",
  "start_time":"HH:MM",
  "end_time":"HH:MM",
  "latitude": 12.97,
  "longitude": 77.59
}
```
- Response: 201 `{ "message":"availability posted" }`

---

## Admin Endpoints (role: admin)
Require admin token.

### GET /api/admin/dashboard
- Returns counts and pending numbers. Example:
```json
{ "staff_count": 10, "hospital_count": 5, "pending_staff": 2, "pending_hospital": 1 }
```

### GET /api/admin/staff/pending
- Returns list of pending staff profiles.

### GET /api/admin/hospital/pending
- Returns list of pending hospital profiles.

### POST /api/admin/staff/{id}/verify
- Approve or reject a staff profile.
- Body:
```json
{ "approve": true }
# or when rejecting:
{ "approve": false, "rejection_reason":"<reason>" }
```
- Response: 200 `{ "message":"updated" }`

### POST /api/admin/hospital/{id}/verify
- Same shape as staff verify, but for hospitals.

---

## Authentication notes
- Obtain JWT by POST `/api/auth/login`.
- Include header: `Authorization: Bearer <token>` for protected routes.
- Role-based middleware enforces access (`RequireRole("staff")`, `RequireRole("hospital")`, `RequireRole("admin")`).

---

## Useful curl snippets
- Login and store token (bash):
```bash
RES=$(curl -s -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d '{"email":"user@x.local","password":"pass"}')
TOKEN=$(echo "$RES" | jq -r .token)
```
- Authenticated GET example:
```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/hospital/dashboard
```

---

## Notes & troubleshooting
- Many actions (posting shifts or availability) require the user to be `verified` by an admin. Use admin verify endpoints or set `verified` in DB for testing.
- Config and port: server port default is `8080` (see `internal/config/config.go`).
- All date/time values are accepted as strings in the format the handlers expect (e.g., `YYYY-MM-DD` and `HH:MM`).

