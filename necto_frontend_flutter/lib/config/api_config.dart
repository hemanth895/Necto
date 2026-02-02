/// Base URL for the Necto backend API.
/// For web: use your backend URL (e.g. http://localhost:8080 when running backend locally).
/// Ensure backend CORS allows your web origin.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);
