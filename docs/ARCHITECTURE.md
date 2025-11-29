# System Architecture

## Overview

The Farm Disease Detection System follows a **client-server architecture** with a Flutter mobile application and an ElysiaJS backend server.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Auth       │  │   Farms     │  │  Requests   │      │
│  │   Feature    │  │   Feature   │  │  Feature    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                │                │                  │
│  ┌──────────────────────────────────────────────┐          │
│  │         Core Providers (State Management)     │          │
│  │  AuthProvider | FarmProvider | RequestProvider │          │
│  └──────────────────────────────────────────────┘          │
│         │                                                   │
│  ┌──────────────────────────────────────────────┐          │
│  │           Shared Services                     │          │
│  │  ApiService | ImageService | LocationService  │          │
│  └──────────────────────────────────────────────┘          │
│         │                                                   │
└─────────┼───────────────────────────────────────────────────┘
          │ HTTP/REST (Bearer Token)
          │
┌─────────┼───────────────────────────────────────────────────┐
│         │         ElysiaJS Backend Server                   │
│  ┌──────▼──────────────────────────────────────┐            │
│  │           API Routes Layer                   │            │
│  │  auth | farms | requests | admin | webhooks │            │
│  └──────┬──────────────────────────────────────┘            │
│         │                                                   │
│  ┌──────▼──────────────────────────────────────┐            │
│  │          Services Layer (Business Logic)    │            │
│  │  farm | request | image | ai | gemini      │            │
│  └──────┬──────────────────────────────────────┘            │
│         │                                                   │
│  ┌──────▼──────────────────────────────────────┐            │
│  │      Repository Layer (Data Access)         │            │
│  │  user | farm | request | image repositories │            │
│  └──────┬──────────────────────────────────────┘            │
│         │                                                   │
│  ┌──────▼──────────────────────────────────────┐            │
│  │         Prisma ORM + SQLite Database         │            │
│  │  User | Farm | Request | Image Models        │            │
│  └─────────────────────────────────────────────┘            │
│                                                              │
│  ┌──────────────────────────────────────────────┐          │
│  │         External Services                     │          │
│  │  Google Gemini API (Macro Images)            │          │
│  │  Python Server Webhook (Normal Images)       │          │
│  └──────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

## Frontend Architecture (Flutter)

### Clean Architecture Layers

```
┌─────────────────────────────────────────┐
│      Presentation Layer                 │
│  - Screens (UI)                         │
│  - Widgets (Reusable components)        │
│  - GoRouter (Navigation)                │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Domain Layer                        │
│  - Entities (Request, Farm, User)       │
│  - Business Logic (in Providers)        │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│      Data Layer                         │
│  - Repositories (API calls)            │
│  - Models (JSON serialization)          │
│  - Services (ApiService, ImageService) │
└─────────────────────────────────────────┘
```

### State Management

**Custom InheritedWidget Pattern:**

```dart
AuthProviderState
  └── AuthProvider (InheritedWidget)
      ├── User state
      ├── Token state
      └── Auth methods (signIn, signUp, logout)

FarmProviderState
  └── FarmProvider (InheritedWidget)
      ├── Farms list
      └── Farm methods (load, create, delete)

RequestProviderState
  └── RequestProvider (InheritedWidget)
      ├── Requests list
      └── Request methods (load, create, send, update)
```

### Navigation (GoRouter)

- **Declarative routing** with type-safe navigation
- **Authentication guards** - redirects unauthenticated users
- **Role-based routing** - admin routes protected
- **Deep linking** support

## Backend Architecture (ElysiaJS)

### Layer Structure

```
Routes (API Endpoints)
    ↓
Middleware (Auth, Validation)
    ↓
Services (Business Logic)
    ↓
Repositories (Data Access)
    ↓
Prisma ORM
    ↓
SQLite Database
```

### Request Flow

1. **HTTP Request** → Route handler
2. **Authentication Middleware** → Verify JWT token
3. **Validation** → Prismabox-generated schemas
4. **Service Layer** → Business logic execution
5. **Repository Layer** → Database operations
6. **Response** → Type-safe JSON response

### Authentication Flow

```
Client Request
    ↓
Bearer Token in Authorization Header
    ↓
authMiddleware extracts token
    ↓
JWT verification
    ↓
User lookup from database
    ↓
User attached to request context
    ↓
Route handler receives authenticated user
```

## Data Flow

### Farm Creation Flow

```
1. User draws polygon on map (Flutter)
   ↓
2. Polygon coordinates sent to API
   ↓
3. Backend calculates area (square meters)
   ↓
4. Farm saved to database
   ↓
5. Response with farm data
   ↓
6. Flutter updates FarmProvider state
   ↓
7. UI refreshes with new farm
```

### Request Processing Flow

```
1. Farmer creates draft request
   ↓
2. Uploads images (normal/macro) with GPS
   ↓
3. Images stored in uploads/ directory
   ↓
4. Image records created in database
   ↓
5. Farmer sends request (DRAFT → PENDING)
   ↓
6. Admin accepts request (PENDING → ACCEPTED)
   ↓
7. AI processing triggered:
   - Normal images → Python server webhook
   - Macro images → Google Gemini API
   ↓
8. Results stored in Image records
   ↓
9. AI generates markdown report
   ↓
10. Admin reviews and edits report
   ↓
11. Request marked as completed
   ↓
12. Farmer views results (map, list, report)
```

## Security Architecture

### Authentication
- **JWT Bearer Tokens** - Stateless authentication
- **Token Storage** - SharedPreferences (Flutter)
- **Token Validation** - Middleware on every request
- **Password Hashing** - bcryptjs (10 rounds)

### Authorization
- **Role-Based Access Control (RBAC)**
  - FARMER: Own farms and requests
  - ADMIN: Full system access
- **Resource Ownership** - Users can only access their own data
- **Admin Middleware** - Protects admin endpoints

### Data Protection
- **Input Validation** - Prismabox-generated schemas
- **SQL Injection Prevention** - Prisma ORM parameterized queries
- **File Upload Security** - Type validation, path sanitization
- **CORS Configuration** - Restricted origins

## AI Integration Architecture

### Normal Image Processing

```
Flutter App
    ↓ (Upload image)
Backend API
    ↓ (Store file)
Python Server (External)
    ↓ (Process image)
Python Server
    ↓ (Webhook callback)
Backend Webhook Endpoint
    ↓ (Update Image record)
Database
```

### Macro Image Processing

```
Flutter App
    ↓ (Upload image)
Backend API
    ↓ (Store file)
Gemini Service
    ↓ (Call Gemini Vision API)
Google Gemini API
    ↓ (Disease detection)
Gemini Service
    ↓ (Parse response)
Backend API
    ↓ (Update Image record)
Database
```

## Scalability Considerations

### Current Architecture
- **SQLite** - Suitable for small to medium deployments
- **File Storage** - Local filesystem (uploads/)
- **Single Server** - Monolithic ElysiaJS server

### Future Scalability Options

**Database:**
- Migrate to PostgreSQL for production
- Add connection pooling
- Implement read replicas

**File Storage:**
- Migrate to cloud storage (S3, Cloudinary)
- CDN for image delivery
- Image optimization pipeline

**Server:**
- Horizontal scaling with load balancer
- Microservices for AI processing
- Queue system for async processing

**Caching:**
- Redis for session management
- Cache frequently accessed data
- CDN for static assets

## Technology Stack

### Frontend
- **Flutter** 3.11+ - Cross-platform framework
- **GoRouter** 14.0 - Navigation
- **flutter_map** 6.1 - Map functionality
- **http** 1.1 - HTTP client
- **shared_preferences** 2.2 - Local storage

### Backend
- **ElysiaJS** - Web framework
- **Bun** - JavaScript runtime
- **Prisma** 6.0 - ORM
- **SQLite** - Database
- **JWT** - Authentication
- **Google Gemini API** - AI processing

### Development Tools
- **TypeScript** - Type safety
- **Dart** - Flutter language
- **Prismabox** - Schema validation
- **OpenAPI** - API documentation

## Design Patterns

### Frontend
- **InheritedWidget Pattern** - State management
- **Repository Pattern** - Data access abstraction
- **Provider Pattern** - Dependency injection
- **Clean Architecture** - Separation of concerns

### Backend
- **Layered Architecture** - Routes → Services → Repositories
- **Middleware Pattern** - Cross-cutting concerns
- **Repository Pattern** - Data access abstraction
- **Service Pattern** - Business logic encapsulation

## Error Handling

### Frontend
- **Try-Catch Blocks** - Async operations
- **Error Snackbars** - User-friendly error messages
- **Loading States** - User feedback during operations
- **Null Safety** - Dart null safety enabled

### Backend
- **Error Middleware** - Centralized error handling
- **HTTP Status Codes** - Proper status responses
- **Error Messages** - Descriptive error responses
- **Logging** - Error logging for debugging

## Performance Optimizations

### Frontend
- **Lazy Loading** - Load data on demand
- **Image Optimization** - Compress before upload
- **State Caching** - Provider state persistence
- **Efficient Rebuilds** - InheritedWidget optimization

### Backend
- **Database Indexing** - Optimized queries
- **Pagination** - Large dataset handling
- **Connection Pooling** - Database connections
- **Async Processing** - Non-blocking operations

---

**Last Updated**: 2024

