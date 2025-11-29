# API Reference

Complete API reference for the Farm Disease Detection System backend.

## Base URL

```
http://localhost:3000
```

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Response Format

### Success Response
```json
{
  "id": "resource-id",
  "field": "value",
  ...
}
```

### Error Response
```json
{
  "error": "Error message",
  "message": "Detailed error description"
}
```

## Authentication Endpoints

### Sign Up
```http
POST /api/auth/sign-up
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "User Name"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "role": "FARMER"
  }
}
```

### Sign In
```http
POST /api/auth/sign-in
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user-id",
    "email": "user@example.com",
    "name": "User Name",
    "role": "FARMER"
  }
}
```

### Get Current User
```http
GET /api/auth/me
Authorization: Bearer <token>
```

**Response:**
```json
{
  "id": "user-id",
  "email": "user@example.com",
  "name": "User Name",
  "role": "FARMER",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

## Farm Endpoints

### Get All Farms
```http
GET /api/farms
Authorization: Bearer <token>
```

**Response:**
```json
[
  {
    "id": "farm-id",
    "userId": "user-id",
    "name": "My Farm",
    "type": "GRAPES",
    "polygon": [
      {"latitude": 36.7538, "longitude": 3.0588},
      {"latitude": 36.7548, "longitude": 3.0598}
    ],
    "area": 1000.0,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
]
```

### Get Farm by ID
```http
GET /api/farms/:id
Authorization: Bearer <token>
```

### Create Farm
```http
POST /api/farms
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "My Farm",
  "type": "GRAPES",
  "polygon": [
    {"latitude": 36.7538, "longitude": 3.0588},
    {"latitude": 36.7548, "longitude": 3.0598},
    {"latitude": 36.7558, "longitude": 3.0588}
  ]
}
```

**Response:**
```json
{
  "id": "farm-id",
  "userId": "user-id",
  "name": "My Farm",
  "type": "GRAPES",
  "polygon": [...],
  "area": 1500.0,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z"
}
```

### Update Farm
```http
PUT /api/farms/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Updated Farm Name",
  "type": "WHEAT",
  "polygon": [...]
}
```

### Delete Farm
```http
DELETE /api/farms/:id
Authorization: Bearer <token>
```

## Request Endpoints

### Get Requests
```http
GET /api/requests?farmId=farm-id
Authorization: Bearer <token>
```

**Query Parameters:**
- `farmId` (required for farmers): Filter by farm ID

**Response:**
```json
[
  {
    "id": "request-id",
    "farmId": "farm-id",
    "status": "DRAFT",
    "expertIntervention": false,
    "note": "Optional note",
    "finalReport": null,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z",
    "completedAt": null,
    "images": [...]
  }
]
```

### Get Request by ID
```http
GET /api/requests/:id
Authorization: Bearer <token>
```

### Create Request
```http
POST /api/requests
Authorization: Bearer <token>
Content-Type: application/json

{
  "farmId": "farm-id"
}
```

**Response:**
```json
{
  "id": "request-id",
  "farmId": "farm-id",
  "status": "DRAFT",
  "expertIntervention": false,
  "note": null,
  "finalReport": null,
  "createdAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T00:00:00.000Z",
  "completedAt": null,
  "images": []
}
```

### Update Request
```http
PUT /api/requests/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "note": "Updated note",
  "expertIntervention": true
}
```

### Upload Image
```http
POST /api/requests/:id/images
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <image-file>
type: NORMAL | MACRO
latitude: 36.7538
longitude: 3.0588
```

**Response:**
```json
{
  "id": "image-id",
  "requestId": "request-id",
  "type": "NORMAL",
  "filePath": "uploads/normal/image.jpg",
  "latitude": 36.7538,
  "longitude": 3.0588,
  "diseaseType": null,
  "confidence": null,
  "treatmentPlan": null,
  "materials": null,
  "services": null,
  "processedAt": null,
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

### Send Request
```http
POST /api/requests/:id/send
Authorization: Bearer <token>
```

**Changes status:** DRAFT → PENDING

### Get Request Report
```http
GET /api/requests/:id/report
Authorization: Bearer <token>
```

**Response:**
```json
{
  "report": "# Disease Detection Report\n\n..."
}
```

## Admin Endpoints

All admin endpoints require ADMIN role.

### User Management

#### Get All Users
```http
GET /api/admin/users
Authorization: Bearer <admin-token>
```

#### Get User by ID
```http
GET /api/admin/users/:id
Authorization: Bearer <admin-token>
```

#### Create User
```http
POST /api/admin/users
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "email": "newuser@example.com",
  "password": "password123",
  "name": "New User",
  "role": "FARMER"
}
```

#### Update User
```http
PUT /api/admin/users/:id
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "email": "updated@example.com",
  "name": "Updated Name",
  "role": "ADMIN"
}
```

#### Delete User
```http
DELETE /api/admin/users/:id
Authorization: Bearer <admin-token>
```

### Farm Management (Admin)

#### Get All Farms
```http
GET /api/admin/farms?userId=user-id
Authorization: Bearer <admin-token>
```

**Query Parameters:**
- `userId` (optional): Filter by user ID

#### Get Farm by ID
```http
GET /api/admin/farms/:id
Authorization: Bearer <admin-token>
```

#### Update Farm
```http
PUT /api/admin/farms/:id
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "name": "Updated Farm",
  "type": "WHEAT",
  "polygon": [...]
}
```

#### Delete Farm
```http
DELETE /api/admin/farms/:id
Authorization: Bearer <admin-token>
```

### Request Management (Admin)

#### Get All Requests
```http
GET /api/admin/requests?status=PENDING
Authorization: Bearer <admin-token>
```

**Query Parameters:**
- `status` (optional): Filter by status (PENDING, ACCEPTED, etc.)

#### Get Request by ID
```http
GET /api/admin/requests/:id
Authorization: Bearer <admin-token>
```

#### Accept Request
```http
POST /api/admin/requests/:id/accept
Authorization: Bearer <admin-token>
```

**Changes status:** PENDING → ACCEPTED

#### Process Request
```http
POST /api/admin/requests/:id/process
Authorization: Bearer <admin-token>
```

**Changes status:** ACCEPTED → PROCESSING
**Triggers:** AI processing for all images

#### Update Request Report
```http
PUT /api/admin/requests/:id/report
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "report": "# Updated Report\n\n..."
}
```

#### Complete Request
```http
POST /api/admin/requests/:id/complete
Authorization: Bearer <admin-token>
```

**Changes status:** PROCESSED → COMPLETED

#### Delete Request
```http
DELETE /api/admin/requests/:id
Authorization: Bearer <admin-token>
```

## Webhook Endpoints

### Python Server Webhook
```http
POST /api/webhooks/python-model
Content-Type: application/json

{
  "imageId": "image-id",
  "diseaseType": "Leaf Spot",
  "confidence": 0.85,
  "treatmentPlan": "Apply fungicide...",
  "materials": "Fungicide X, Sprayer",
  "services": "Contact agricultural expert"
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `204` - No Content
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error

## Error Responses

### Unauthorized
```json
{
  "error": "Unauthorized",
  "message": "Invalid or missing token"
}
```

### Forbidden
```json
{
  "error": "Forbidden",
  "message": "Admin access required"
}
```

### Not Found
```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

### Validation Error
```json
{
  "error": "Validation Error",
  "message": "Invalid input data",
  "details": {
    "field": "Error message"
  }
}
```

## Rate Limiting

Currently no rate limiting implemented. Consider adding for production.

## OpenAPI Documentation

Interactive API documentation available at:
- **Swagger UI**: `http://localhost:3000/openapi`
- **JSON Spec**: `http://localhost:3000/openapi/json`

## Examples

### Complete Workflow Example

1. **Sign Up:**
```bash
curl -X POST http://localhost:3000/api/auth/sign-up \
  -H "Content-Type: application/json" \
  -d '{"email":"farmer@example.com","password":"password123","name":"Farmer Name"}'
```

2. **Create Farm:**
```bash
curl -X POST http://localhost:3000/api/farms \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Vineyard",
    "type": "GRAPES",
    "polygon": [
      {"latitude": 36.7538, "longitude": 3.0588},
      {"latitude": 36.7548, "longitude": 3.0598},
      {"latitude": 36.7558, "longitude": 3.0588}
    ]
  }'
```

3. **Create Request:**
```bash
curl -X POST http://localhost:3000/api/requests \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"farmId": "farm-id"}'
```

4. **Upload Image:**
```bash
curl -X POST http://localhost:3000/api/requests/request-id/images \
  -H "Authorization: Bearer <token>" \
  -F "file=@image.jpg" \
  -F "type=NORMAL" \
  -F "latitude=36.7538" \
  -F "longitude=3.0588"
```

5. **Send Request:**
```bash
curl -X POST http://localhost:3000/api/requests/request-id/send \
  -H "Authorization: Bearer <token>"
```

---

**Last Updated**: 2024

