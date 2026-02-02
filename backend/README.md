# Necto Backend (Go + PostgreSQL)

REST API backend mirroring the endpoints from the PHP app in `public_html (4)`. Uses Go, Chi router, JWT auth, and PostgreSQL. No UI—API only.

## Run with Docker

```bash
cd backend
docker compose up --build
```

- **API**: http://localhost:8080  
- **PostgreSQL**: localhost:5432 (user `necto`, password `necto`, db `necto_db`)

Migrations in `migrations/001_init.sql` run automatically on first Postgres startup (via `docker-entrypoint-initdb.d`).

## Run locally (no Docker)

1. Start PostgreSQL and create database `necto_db`, user `necto`/password `necto`.
2. Run migrations: `psql -U necto -d necto_db -f migrations/001_init.sql`
3. Install deps and run:
   ```bash
   go mod tidy
   go run ./cmd/api
   ```
4. Set env if needed: `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `JWT_SECRET`, `PORT` (default 8080).

## API Endpoints (same behaviour as PHP app)

All authenticated routes require header: `Authorization: Bearer <token>`.

### Auth (no token)
- `POST /api/auth/login` — body: `{"email","password"}` → `{token, role, id}`
- `POST /api/auth/register` — body: `{name, email, password, role: "hospital"|"staff", agree_terms}`
- `POST /api/auth/forgot-password` — body: `{email}`
- `POST /api/auth/reset-password` — body: `{email, password}`

### Hospital (role: hospital)
- `GET /api/hospital/profile` — get/create hospital profile
- `POST /api/hospital/profile` — create profile (body: hospital_name, address, telephone, contact_number, pincode, hospital_image, consent)
- `GET /api/hospital/dashboard` — dashboard summary
- `POST /api/hospital/shifts` — post shift (shift_date, start_time, end_time, degree_required, stream_required, role_required, latitude, longitude, payment_amount, payment_type, notes)
- `GET /api/hospital/shifts/:id/available-staff` — list available staff for shift (by degree/stream/date/time and distance)

### Staff (role: staff)
- `GET /api/staff/profile` — get profile status
- `POST /api/staff/profile` — create staff profile (full_name, age, dob, gender, address, email, mobile, emergency_mobile, degree, stream, college, experience_years, current_institution, working_role, willing_roles, preferred_location, profile_photo, consent)
- `GET /api/staff/dashboard` — dashboard summary
- `POST /api/staff/availability` — post availability (district, taluka, work_date, start_time, end_time, latitude, longitude)

### Admin (role: admin)
- `GET /api/admin/dashboard` — counts (staff_count, hospital_count, pending_staff, pending_hospital)
- `GET /api/admin/staff/pending` — list pending staff for verification
- `GET /api/admin/hospital/pending` — list pending hospitals for verification
- `POST /api/admin/staff/:id/verify` — body: `{approve: bool, rejection_reason?}` (id = staff_profiles.id)
- `POST /api/admin/hospital/:id/verify` — body: `{approve: bool, rejection_reason?}` (id = hospital_profiles.id)

### Health
- `GET /health` — `{"status":"ok"}`

## Environment

| Variable     | Default |
|-------------|---------|
| PORT        | 8080    |
| DB_HOST     | localhost |
| DB_PORT     | 5432    |
| DB_USER     | necto   |
| DB_PASSWORD | necto   |
| DB_NAME     | necto_db |
| DB_SSLMODE  | disable |
| JWT_SECRET  | (set in production) |
