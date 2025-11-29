# Flutter API Tests

This directory contains comprehensive unit tests for all API endpoints used in the Flutter app.

## Test Files

### 1. `api_service_test.dart`
Tests for the core `ApiService` class:
- Token management (set, get, clear, load from SharedPreferences)
- GET, POST, PUT, DELETE request methods
- Response handling (empty body, JSON, error codes)
- Authorization header inclusion

**Status:** 5 passing, 7 failing (SharedPreferences mocking issues)

### 2. `auth_api_test.dart`
Tests for authentication endpoints:
- Sign up (user registration)
- Sign in (user login)
- Get current user (`/api/auth/me`)
- Token persistence

**Status:** All tests passing ✅

### 3. `farms_api_test.dart`
Tests for farm management endpoints:
- Get all farms (`GET /api/farms`)
- Create farm (`POST /api/farms`)
- Get farm by ID (`GET /api/farms/:id`)
- Update farm (`PUT /api/farms/:id`)
- Delete farm (`DELETE /api/farms/:id`)
- Farm type validation
- Polygon validation
- Authorization checks

**Status:** All tests passing ✅

### 4. `requests_api_test.dart`
Tests for request management endpoints:
- Get requests (`GET /api/requests?farmId=...`)
- Create request (`POST /api/requests`)
- Upload image (normal and macro)
- Send request (`POST /api/requests/:id/send`)
- Get request by ID (`GET /api/requests/:id`)
- Request status validation

**Status:** All tests passing ✅

### 5. `admin_api_test.dart`
Tests for admin-only endpoints:
- User management (CRUD operations)
- Farm management (admin operations)
- Request management (accept, process, complete, update report)
- Authorization checks

**Status:** All tests passing ✅

## Running Tests

```bash
# Run all API tests
flutter test test/api/

# Run specific test file
flutter test test/api/auth_api_test.dart

# Run with coverage
flutter test --coverage test/api/
```

## Test Coverage

The tests cover:
- ✅ All authentication endpoints
- ✅ All farm CRUD operations
- ✅ All request operations
- ✅ All admin operations
- ✅ Token management
- ✅ Request/response validation
- ✅ Error handling
- ⚠️ SharedPreferences integration (some tests need mocking improvements)

## Notes

- Tests use `mockito` for HTTP client mocking
- `SharedPreferences` requires `TestWidgetsFlutterBinding.ensureInitialized()` before use
- Some tests validate request structure and response format without making actual HTTP calls
- Tests are designed to validate API contract compliance

## Future Improvements

1. Fix SharedPreferences mocking in `api_service_test.dart`
2. Add integration tests that make actual HTTP calls to a test server
3. Add tests for multipart file uploads
4. Add tests for error scenarios (network errors, timeouts, etc.)

