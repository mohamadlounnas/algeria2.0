# Farm Disease Detection System

A comprehensive farm disease detection system with Flutter mobile app and ElysiaJS backend, featuring AI-powered image analysis for early disease detection in agricultural crops.

## 🎯 Overview

This system enables farmers to:
- Create and manage farms with polygon boundaries
- Submit disease detection requests with images
- Receive AI-powered analysis and treatment recommendations
- View results on interactive maps with disease markers

Admins can:
- Review and process all requests
- Manage users, farms, and requests
- Edit AI-generated reports
- Monitor system activity

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter with Clean Architecture
- **State Management**: Custom InheritedWidget providers
- **Routing**: GoRouter for declarative navigation
- **Maps**: flutter_map for polygon drawing and disease visualization
- **Image Capture**: image_picker with GPS location tagging
- **API Communication**: HTTP client with Bearer token authentication

### Backend (ElysiaJS)
- **Framework**: ElysiaJS (Bun runtime)
- **Database**: SQLite with Prisma ORM
- **Authentication**: JWT Bearer tokens
- **API Documentation**: OpenAPI with Scalar UI
- **AI Integration**: 
  - Google Gemini API for macro image analysis
  - Custom Python server webhook for normal image processing

## 📁 Project Structure

```
dowa/
├── app/                    # Flutter mobile application
│   ├── lib/
│   │   ├── core/          # Core functionality
│   │   │   ├── providers/ # State management (Auth, Farm, Request)
│   │   │   ├── routing/   # GoRouter configuration
│   │   │   ├── theme/     # Design system
│   │   │   └── constants/ # API endpoints
│   │   ├── features/      # Feature modules
│   │   │   ├── auth/      # Authentication screens
│   │   │   ├── farms/     # Farm management
│   │   │   ├── requests/  # Request management
│   │   │   └── admin/     # Admin dashboard
│   │   └── shared/        # Shared services & widgets
│   └── test/              # Unit tests (55 tests)
│
├── server/                 # ElysiaJS backend
│   ├── src/
│   │   ├── routes/        # API route handlers
│   │   ├── services/      # Business logic
│   │   ├── repositories/ # Data access layer
│   │   ├── auth/          # Authentication middleware
│   │   └── plugins/       # Elysia plugins (CORS, OpenAPI)
│   ├── prisma/            # Database schema & migrations
│   └── uploads/           # Image storage
│
└── docs/                   # Documentation (this directory)
```

## 🚀 Quick Start

### Prerequisites
- **Bun** (v1.0+): [Install Bun](https://bun.sh)
- **Flutter** (v3.11+): [Install Flutter](https://flutter.dev)
- **Node.js** (optional, for Python server)

### Backend Setup

1. **Navigate to server directory:**
```bash
cd server
```

2. **Install dependencies:**
```bash
bun install
```

3. **Set up environment variables:**
```bash
cp .env.example .env
# Edit .env with your configuration
```

Required environment variables:
- `DATABASE_URL`: SQLite database path (default: `file:./prisma/dev.db`)
- `JWT_SECRET`: Secret key for JWT token signing
- `GEMINI_API_KEY`: Google Gemini API key (for macro image analysis)
- `PORT`: Server port (default: 3000)

4. **Generate Prisma client:**
```bash
bunx prisma generate
```

5. **Run database migrations:**
```bash
bunx prisma migrate dev
```

6. **Seed the database:**
```bash
bun run db:seed
```

7. **Start the development server:**
```bash
bun run dev
```

The server will be available at `http://localhost:3000`
- OpenAPI Documentation: `http://localhost:3000/openapi`
- OpenAPI JSON: `http://localhost:3000/openapi/json`

### Frontend Setup

1. **Navigate to app directory:**
```bash
cd app
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run the app:**
```bash
flutter run
```

## 📚 Documentation

### Backend Documentation
- [API Documentation](./server/README.md) - Backend setup and API endpoints
- [Authentication Guide](./AUTHENTICATION.md) - Authentication flow
- [Bearer Token Auth](./BEARER_TOKEN_AUTH.md) - JWT implementation
- [OpenAPI Docs](./server/OPENAPI.md) - API documentation setup
- [Testing Guide](./server/TESTING.md) - Backend testing
- [Prismabox Integration](./server/PRISMABOX.md) - Schema validation

### Frontend Documentation
- [Flutter App README](./app/README.md) - Mobile app setup
- [API Tests](./app/test/api/README.md) - Frontend API tests

## 🔐 Authentication

The system uses **Bearer Token (JWT) authentication**:

1. **Sign Up/Sign In**: User receives a JWT token
2. **Token Storage**: Token stored in SharedPreferences (Flutter)
3. **API Requests**: Token included in `Authorization: Bearer <token>` header
4. **Token Validation**: Backend verifies token on each request

See [AUTHENTICATION.md](./AUTHENTICATION.md) for detailed flow.

## 🗄️ Database Schema

### Models

**User**
- id, email, password (hashed), name, role (FARMER | ADMIN)

**Farm**
- id, userId, name, type (GRAPES | WHEAT | CORN | TOMATOES | OLIVES | DATES)
- polygon (JSON array of LatLng), area (square meters)

**Request**
- id, farmId, status (DRAFT | PENDING | ACCEPTED | PROCESSING | PROCESSED | COMPLETED)
- expertIntervention, note, finalReport (markdown)

**Image**
- id, requestId, type (NORMAL | MACRO), filePath
- latitude, longitude (GPS coordinates)
- diseaseType, confidence, treatmentPlan, materials, services

See [server/prisma/schema.prisma](./server/prisma/schema.prisma) for full schema.

## 🔄 Request Workflow

### Farmer Workflow

1. **Create Farm**
   - Draw polygon boundary on map
   - System calculates area automatically

2. **Create Request**
   - Create draft request for a farm
   - Upload images (normal and/or macro) with GPS location
   - Add notes and expert intervention option
   - Send request (status: DRAFT → PENDING)

3. **View Results** (after admin processing)
   - Interactive map with disease markers
   - Disease list with treatment plans
   - Final markdown report

### Admin Workflow

1. **Review Requests**
   - View all requests with status filtering
   - See request details and images

2. **Process Request**
   - Accept request (PENDING → ACCEPTED)
   - Trigger AI processing (ACCEPTED → PROCESSING)
   - Review AI results (PROCESSING → PROCESSED)

3. **Complete Request**
   - Edit final report (markdown editor)
   - Mark as completed (PROCESSED → COMPLETED)

## 🤖 AI Processing

### Normal Images
- Sent to custom Python server via webhook
- Python server processes and calls webhook endpoint
- Results stored in Image record

### Macro Images
- Processed directly by Google Gemini Vision API
- Disease detection with confidence scores
- Treatment recommendations generated

### Report Generation
- AI agent analyzes all processed images
- Generates comprehensive markdown report
- Includes disease distribution, treatment plans, materials needed

## 🧪 Testing

### Backend Tests
```bash
cd server
bun test
```

### Frontend Tests
```bash
cd app
flutter test
```

**Test Coverage:**
- Backend: Unit tests for all services and repositories
- Frontend: 55 unit tests covering all API endpoints
- Integration: API test scripts for end-to-end verification

## 📡 API Endpoints

### Authentication
- `POST /api/auth/sign-up` - Register new user
- `POST /api/auth/sign-in` - Sign in user
- `GET /api/auth/me` - Get current user

### Farms
- `GET /api/farms` - List user's farms
- `POST /api/farms` - Create farm
- `GET /api/farms/:id` - Get farm details
- `PUT /api/farms/:id` - Update farm
- `DELETE /api/farms/:id` - Delete farm

### Requests
- `GET /api/requests?farmId=:id` - List requests
- `POST /api/requests` - Create draft request
- `GET /api/requests/:id` - Get request details
- `PUT /api/requests/:id` - Update request
- `POST /api/requests/:id/images` - Upload image
- `POST /api/requests/:id/send` - Send request
- `GET /api/requests/:id/report` - Get report

### Admin
- `GET /api/admin/users` - List all users
- `POST /api/admin/users` - Create user
- `PUT /api/admin/users/:id` - Update user
- `DELETE /api/admin/users/:id` - Delete user
- `GET /api/admin/farms` - List all farms
- `GET /api/admin/requests` - List all requests
- `POST /api/admin/requests/:id/accept` - Accept request
- `POST /api/admin/requests/:id/process` - Process request
- `PUT /api/admin/requests/:id/report` - Update report
- `POST /api/admin/requests/:id/complete` - Complete request

Full API documentation available at `/openapi` when server is running.

## 🎨 Design System

The Flutter app uses a **dashboard-style design**:
- Bordered cards (no shadows)
- Uniform padding (8px, 16px, 24px scale)
- Professional, muted color scheme
- IBM-style dashboard aesthetics

## 🔧 Development

### Backend Development
```bash
cd server
bun run dev  # Watch mode
```

### Frontend Development
```bash
cd app
flutter run  # Hot reload enabled
```

### Database Management
```bash
cd server
bun run db:generate  # Generate Prisma client
bun run db:migrate   # Run migrations
bun run db:seed      # Seed database
bun run db:reset     # Reset and reseed
```

## 📦 Dependencies

### Backend
- **elysia** - Web framework
- **@prisma/client** - Database ORM
- **@elysiajs/jwt** - JWT authentication
- **@elysiajs/openapi** - API documentation
- **@google/generative-ai** - Gemini API
- **bcryptjs** - Password hashing

### Frontend
- **flutter_map** - Map widget
- **go_router** - Navigation
- **image_picker** - Image capture
- **geolocator** - GPS location
- **http** - API communication
- **shared_preferences** - Local storage
- **flutter_markdown** - Report display

## 🚨 Troubleshooting

### Backend Issues

**Prisma generate fails:**
```bash
# Use bunx instead of npx
bunx prisma generate
```

**Database not found:**
```bash
# Ensure DATABASE_URL is set
export DATABASE_URL="file:./prisma/dev.db"
bunx prisma db push
```

### Frontend Issues

**Dependencies conflict:**
```bash
flutter pub get
flutter clean
flutter pub get
```

**Tests failing:**
```bash
# Ensure SharedPreferences is mocked
flutter test --no-sound-null-safety
```

## 📝 License

This project is private and not licensed for public use.

## 👥 Contributing

This is a private project. For questions or issues, contact the project maintainer.

## 📞 Support

For technical support or questions:
- Check documentation in `/docs` directory
- Review API documentation at `/openapi`
- Check test files for usage examples

---

**Last Updated**: 2024
**Version**: 1.0.0

