# Authentication Flow

## How Authentication Works

This app uses **Better Auth** with **cookie-based sessions**, not JWT tokens.

### Backend (Better Auth)

Better Auth uses HTTP-only cookies for session management:

1. **Sign In/Sign Up**: User authenticates via `/api/auth/sign-in` or `/api/auth/sign-up`
2. **Session Cookie**: Better Auth sets a `better-auth.session_token` cookie
3. **Session Validation**: Backend validates session from cookie on each request
4. **Session Expiry**: Sessions expire after 7 days, refresh after 1 day of inactivity

### Frontend (Flutter)

The Flutter app handles authentication as follows:

1. **Sign In/Sign Up**: Makes POST request to Better Auth endpoints
2. **Cookie Storage**: Extracts `better-auth.session_token` from response headers
3. **Cookie Persistence**: Saves cookie to SharedPreferences for app restarts
4. **Automatic Cookie Sending**: Includes cookie in all subsequent API requests
5. **Session Check**: On app start, checks `/api/auth/session` to restore user

## Authentication Endpoints

### Sign Up
```dart
POST /api/auth/sign-up
Body: {
  "email": "user@example.com",
  "password": "password123",
  "name": "User Name"
}
Response: {
  "user": { "id": "...", "email": "...", "name": "...", "role": "FARMER" }
}
// Sets better-auth.session_token cookie
```

### Sign In
```dart
POST /api/auth/sign-in
Body: {
  "email": "user@example.com",
  "password": "password123"
}
Response: {
  "user": { "id": "...", "email": "...", "name": "...", "role": "FARMER" },
  "session": { "id": "...", "expiresAt": "..." }
}
// Sets better-auth.session_token cookie
```

### Get Session
```dart
GET /api/auth/session
Headers: Cookie: better-auth.session_token=...
Response: {
  "user": { "id": "...", "email": "...", "name": "...", "role": "FARMER" },
  "session": { "id": "...", "expiresAt": "..." }
}
```

### Sign Out
```dart
POST /api/auth/sign-out
Headers: Cookie: better-auth.session_token=...
Response: { "success": true }
// Clears session cookie
```

## Cookie vs Token

### Why Cookies Instead of Tokens?

1. **Security**: HTTP-only cookies prevent XSS attacks
2. **Automatic**: Browser/app handles cookie management
3. **Better Auth**: Better Auth is designed for cookie-based sessions
4. **CSRF Protection**: Better Auth includes CSRF protection

### How It Works in Flutter

Since Flutter doesn't have automatic cookie handling like browsers:

1. **Extract Cookie**: Parse `Set-Cookie` header from response
2. **Store Cookie**: Save to SharedPreferences
3. **Send Cookie**: Include in `Cookie` header for all requests
4. **Clear Cookie**: Remove on logout

## Implementation Details

### ApiService
- Extracts cookies from response headers
- Stores cookies in SharedPreferences
- Automatically includes cookies in request headers
- Clears cookies on logout

### AuthProvider
- Manages user state
- Handles sign-in/sign-up/logout
- Restores session on app start
- Provides user info to app

## Testing Authentication

### Using curl
```bash
# Sign up
curl -X POST http://localhost:3000/api/auth/sign-up \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}' \
  -c cookies.txt

# Sign in
curl -X POST http://localhost:3000/api/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}' \
  -c cookies.txt

# Get session (uses cookie from cookies.txt)
curl http://localhost:3000/api/auth/session -b cookies.txt

# Sign out
curl -X POST http://localhost:3000/api/auth/sign-out -b cookies.txt
```

## Session Configuration

Sessions are configured in `server/src/auth/better-auth.ts`:

- **Expires In**: 7 days (60 * 60 * 24 * 7 seconds)
- **Update Age**: 1 day (session refreshes after 1 day of inactivity)

