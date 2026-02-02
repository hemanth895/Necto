# Necto Flutter Frontend

Web-first Flutter app for the Necto healthcare staffing platform. Connects to the Necto Go backend API.

## Run (web)

```bash
cd necto_frontend_flutter
flutter pub get
flutter run -d chrome
```

Or build for release:

```bash
flutter build web
```

## Backend URL

By default the app calls `http://localhost:8080`. Override with:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://your-api.example.com
```

Or when building:

```bash
flutter build web --dart-define=API_BASE_URL=https://your-api.example.com
```

## CORS (web)

When running in the browser, the backend must allow your web origin. The Necto Go backend does not enable CORS by default; add CORS middleware (e.g. allow `http://localhost:*` for local dev) so the web app can call the API.

## Features

- **Landing** – Hero, roles, how it works, CTA
- **Auth** – Login, register (hospital/staff), forgot password, reset password
- **Hospital** – Dashboard, create profile, post shift, view available staff (by shift)
- **Staff** – Dashboard, create profile, post availability (district/taluka, date, time, location)
- **Admin** – Dashboard counts, verify staff, verify hospitals (approve/reject with reason)

Layout is web-first (max-width constraint); structure is ready to extend for mobile later.
