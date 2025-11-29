# Bearer Token Authentication

The app now uses **JWT Bearer Token** authentication instead of cookie-based sessions.

## How It Works

### Backend (ElysiaJS + JWT)

1. **Sign Up/Sign In**: User authenticates via `/api/auth/sign-up` or `/api/auth/sign-in`
2. **Token Generation**: Server generates a JWT token containing user info (id, email, role)
3. **Token Return**: Server returns the token in the response
4. **Token Validation**: Middleware validates Bearer token from `Authorization` header on each request

### Frontend (Flutter)

1. **Sign In/Sign Up**: Makes POST request to auth endpoints
2. **Token Storage**: Saves JWT token to SharedPreferences
3. **Token Sending**: Includes token in `Authorization: Bearer <token>` header for all requests
4. **Token Validation**: On app start, checks `/api/auth/me` to verify token and restore user

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
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "user@example.com",
    "name": "User Name",
    "role": "FARMER"
  }
}
```

### Sign In
```dart
POST /api/auth/sign-in
Body: {
  "email": "user@example.com",
  "password": "password123"
}
Response: {
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "...",
    "email": "user@example.com",
    "name": "User Name",
    "role": "FARMER"
  }
}
```

### Get Current User
```dart
GET /api/auth/me
Headers: Authorization: Bearer <token>
Response: {
  "id": "...",
  "email": "user@example.com",
  "name": "User Name",
  "role": "FARMER",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Implementation Details

### Backend

- **JWT Plugin**: `@elysiajs/jwt` for token generation/verification
- **Bearer Plugin**: `@elysiajs/bearer` for extracting token from Authorization header
- **Password Hashing**: Uses `bcryptjs` for secure password hashing
- **Token Payload**: Contains `{ id, email, role }`
- **Token Secret**: Configured via `JWT_SECRET` environment variable

### Frontend

- **Token Storage**: Saved to SharedPreferences as `auth_token`
- **Automatic Inclusion**: Token automatically added to `Authorization` header
- **Token Persistence**: Token persists across app restarts
- **Token Validation**: Validates token on app start via `/api/auth/me`

## Security

- **JWT Secret**: Must be set in environment variables (change in production!)
- **Password Hashing**: Passwords are hashed with bcrypt (10 rounds)
- **Token Expiry**: JWT tokens can include expiration (currently no expiry set)
- **HTTPS**: Use HTTPS in production to protect tokens in transit

## Testing

### Using curl
```bash
# Sign up
curl -X POST http://localhost:3000/api/auth/sign-up \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Sign in
curl -X POST http://localhost:3000/api/auth/sign-in \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get current user (use token from sign-in response)
curl http://localhost:3000/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## OpenAPI Documentation

Bearer token authentication is documented in OpenAPI with:
- Security scheme: `bearerAuth` (JWT)
- All protected endpoints require Bearer token
- Interactive testing in Scalar UI supports Bearer token input

## Migration from Cookie-Based Auth

The app has been migrated from cookie-based to token-based authentication:
- ✅ Removed cookie handling
- ✅ Added JWT token generation
- ✅ Updated middleware to validate Bearer tokens
- ✅ Updated Flutter app to use Bearer tokens
- ✅ Updated OpenAPI documentation

