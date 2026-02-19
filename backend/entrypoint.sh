#!/usr/bin/env sh
set -e

# Build Postgres connection string from env vars used by the app.
DB_USER="${DB_USER:-necto}"
DB_PASSWORD="${DB_PASSWORD:-necto}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-necto_db}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

DSN="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"

echo "Running database migrations..."
psql "$DSN" -f migrations/001_init.sql
psql "$DSN" -f migrations/002_shift_requests_notifications.sql
echo "Migrations completed."

echo "Starting API server..."
exec ./api

