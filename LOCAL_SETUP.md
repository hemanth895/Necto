# Necto - Local Development Setup Guide

This guide covers setting up and running both the **Backend (Go + PostgreSQL)** and **Frontend (Flutter)** locally.

## Prerequisites

### System Requirements
- **macOS 12+** (or Linux/Windows with adapted commands)
- **Docker & Docker Compose** (for easy backend setup)
- **Flutter SDK 3.9.2+**
- **Go 1.21+** (if running backend without Docker)
- **Git**

### Install Required Tools

#### 1. Flutter
```bash
# Check if already installed
flutter --version

# If not installed, download from https://flutter.dev/docs/get-started/install
# Add to PATH in ~/.zshrc or ~/.bash_profile
export PATH="$PATH:/Users/hemanth/sdks/flutter/bin"
```

#### 2. Docker & Docker Compose
```bash
# Install Docker Desktop from https://www.docker.com/products/docker-desktop
# Or use Homebrew:
brew install docker docker-compose
```

#### 3. Go (Optional - only if running backend without Docker)
```bash
# Check if installed
go version

# Install via Homebrew if needed:
brew install go
```

---

## Backend Setup

### Option A: Run with Docker (Recommended)

```bash
cd backend
docker compose up --build
```

**What starts:**
- **API Server**: http://localhost:8080
- **PostgreSQL Database**: localhost:5432

**Access database directly:**
```bash
psql -h localhost -U necto -d necto_db -p 5432
# Password: necto
```

**Check API health:**
```bash
curl http://localhost:8080/health
# Response: {"status":"ok"}
```

**Stop services:**
```bash
docker compose down
# Remove volumes too (clears database):
docker compose down -v
```

---

### Option B: Run Locally (without Docker)

#### 1. Set up PostgreSQL

```bash
# Install PostgreSQL (if needed)
brew install postgresql

# Start PostgreSQL service
brew services start postgresql

# Create database and user
psql -U postgres
postgres=# CREATE USER necto WITH PASSWORD 'necto';
postgres=# CREATE DATABASE necto_db OWNER necto;
postgres=# GRANT ALL PRIVILEGES ON DATABASE necto_db TO necto;
postgres=# \q

# Verify connection
psql -h localhost -U necto -d necto_db
```

#### 2. Run migrations

```bash
cd backend
psql -U necto -d necto_db -f migrations/001_init.sql
```

#### 3. Set environment variables (optional)

```bash
# Create .env file in backend/
cat > backend/.env <<EOF
PORT=8080
DB_HOST=localhost
DB_PORT=5432
DB_USER=necto
DB_PASSWORD=necto
DB_NAME=necto_db
DB_SSLMODE=disable
JWT_SECRET=necto-jwt-secret-change-in-production
EOF

# Load variables
export $(cat backend/.env | xargs)
```

#### 4. Install Go dependencies and run

```bash
cd backend
go mod tidy
go run ./cmd/api
```

**Output should show:**
```
Server running on http://localhost:8080
Connected to PostgreSQL at localhost:5432
```

---

## Frontend Setup

### iOS or Android Development

#### 1. Install Flutter dependencies

```bash
cd necto_frontend_flutter
flutter pub get
```

#### 2. Configure API endpoint (Optional)

By default, the app connects to `http://localhost:8080`. To change:

**For Flutter app (local dev):**
```bash
# Run with custom API URL
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8080
```

**To make permanent, edit `lib/config/api_config.dart`:**
```dart
const String kApiBaseUrl = 'http://your-backend-url:8080';
```

---

### Run on iOS Emulator

```bash
cd necto_frontend_flutter

# Start iOS simulator
open -a Simulator

# Run app
flutter run -d <device-id>

# Or let Flutter pick:
flutter run
```

**Troubleshooting:**
```bash
# List available devices
flutter devices

# Clean build if issues occur
flutter clean
flutter pub get
flutter run
```

---

### Run on Android Emulator

```bash
cd necto_frontend_flutter

# Start Android emulator
emulator -avd <emulator-name>

# List available emulators
emulator -list-avds

# Run app
flutter run

# Or specify device
flutter run -d emulator-5554
```

**Note:** The `local.properties` file is already configured with correct paths:
```
sdk.dir=/Users/hemanth/Library/Android/sdk
flutter.sdk=/Users/hemanth/sdks/flutter
```

---

### Run on Web

```bash
cd necto_frontend_flutter

# Run on default browser
flutter run -d chrome

# Or specify port
flutter run -d chrome --web-port=8888
```

**Access at:** http://localhost:8888

---

## Quick Start (All Services)

### Start Everything in One Go

```bash
# Terminal 1: Start Backend
cd backend
docker compose up --build

# Terminal 2: Start Frontend
cd necto_frontend_flutter
flutter run

# Terminal 3: (Optional) View database
psql -h localhost -U necto -d necto_db
```

### Verify Setup

```bash
# Test Backend Health
curl http://localhost:8080/health

# Test Frontend Connection
# Open app in emulator/device/web and check login screen loads
```

---

## Common Issues & Solutions

### Backend Issues

| Issue | Solution |
|-------|----------|
| `docker: command not found` | Install Docker Desktop |
| `postgres: ERROR: database "necto_db" already exists` | Run `docker compose down -v` to reset |
| `JWT_SECRET not set` | Default value is used in docker-compose.yml |
| Port 8080 already in use | Change `PORT` env var or kill process: `lsof -ti:8080 \| xargs kill -9` |

### Frontend Issues

| Issue | Solution |
|-------|----------|
| `Flutter SDK not found` | Update `local.properties` with correct Flutter path |
| `Android SDK not found` | Set `sdk.dir` in `android/local.properties` |
| API connection fails | Ensure backend is running on `http://localhost:8080` |
| Emulator won't start | Run `flutter doctor` to diagnose |
| `pub get` fails | Run `flutter clean` then `flutter pub get` again |

---

## Environment Variables

### Backend (docker-compose.yml or .env)

| Variable | Default | Notes |
|----------|---------|-------|
| `PORT` | 8080 | API server port |
| `DB_HOST` | postgres | Database host (use "postgres" in Docker) |
| `DB_PORT` | 5432 | Database port |
| `DB_USER` | necto | Database user |
| `DB_PASSWORD` | necto | Database password |
| `DB_NAME` | necto_db | Database name |
| `DB_SSLMODE` | disable | SSL mode (disable for local dev) |
| `JWT_SECRET` | necto-jwt-secret-change-in-production | JWT signing secret |

### Frontend (lib/config/api_config.dart)

```dart
const String kApiBaseUrl = 'http://localhost:8080';
```

---

## Development Workflow

### Database Changes

If you modify the schema, create a new migration:

```bash
# Example: Add a new table
cat > backend/migrations/002_add_table.sql <<EOF
CREATE TABLE new_table (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF

# Reset and rerun migrations
docker compose down -v
docker compose up --build
```

### Code Changes

**Backend:**
```bash
# Rebuild and restart
docker compose up --build

# Or if running locally, changes auto-restart with certain Go tools
# For manual restart: Ctrl+C then `go run ./cmd/api`
```

**Frontend:**
```bash
# Hot reload (most changes)
# Press 'r' in terminal running `flutter run`

# Full rebuild (if dependencies changed)
flutter clean
flutter pub get
flutter run
```

---

## Testing API Endpoints

```bash
# Get authentication token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Response: {"token":"eyJ...","role":"staff","id":1}

# Use token in subsequent requests
curl -X GET http://localhost:8080/api/staff/profile \
  -H "Authorization: Bearer eyJ..."
```

---

## Useful Commands

```bash
# Flutter
flutter doctor                    # Check Flutter setup
flutter pub get                  # Install dependencies
flutter clean                    # Clean build files
flutter run                      # Run app
flutter pub upgrade              # Upgrade packages
flutter format lib/              # Format code

# Backend (Docker)
docker compose up                # Start services
docker compose down              # Stop services
docker compose logs -f           # View logs
docker ps                        # List running containers

# Backend (Local)
go mod tidy                      # Manage dependencies
go run ./cmd/api                 # Run server
go test ./...                    # Run tests

# Database
psql -h localhost -U necto -d necto_db  # Connect to DB
\dt                              # List tables
\q                               # Quit psql
```

---

## Support & Debugging

### Enable verbose logging

**Flutter:**
```bash
flutter run -v   # Verbose output
```

**Backend:**
```bash
# Check logs in docker compose
docker compose logs -f api
```

### Run diagnostics

```bash
# Flutter
flutter doctor -v

# Go
go version
go env

# Docker
docker ps
docker logs <container-id>
```

---

## Next Steps

1. ✅ Clone the repository (already done)
2. ✅ Install prerequisites (Flutter, Docker, Go)
3. ✅ Run backend: `cd backend && docker compose up`
4. ✅ Run frontend: `cd necto_frontend_flutter && flutter run`
5. 🔍 Test login with test credentials
6. 📱 Start development!

---

**Happy coding! 🚀**
