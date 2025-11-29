# Features Documentation

## Overview

This document provides a comprehensive overview of all features implemented in the Farm Disease Detection System.

## 👤 User Roles

### Farmer
- Create and manage farms
- Submit disease detection requests
- Upload images with GPS location
- View detection results and reports

### Admin
- Manage all users, farms, and requests
- Review and process requests
- Edit AI-generated reports
- Monitor system activity

## 🔐 Authentication Features

### Sign Up
- **Email validation** - Ensures valid email format
- **Password requirements** - Minimum 8 characters
- **Name field** - Full name collection
- **Auto-login** - Automatic sign-in after registration
- **Role assignment** - Defaults to FARMER role

### Sign In
- **Email/password authentication**
- **Token-based session** - JWT token storage
- **Session persistence** - Token saved in SharedPreferences
- **Auto-redirect** - Redirects to farms list after login

### Session Management
- **Token persistence** - Survives app restarts
- **Token validation** - Automatic token verification
- **Auto-logout** - Logout on invalid token
- **Secure storage** - Tokens stored securely

## 🚜 Farm Management Features

### Create Farm
- **Farm name input** - Text field with validation
- **Farm type selection** - Dropdown with available types:
  - GRAPES (enabled)
  - WHEAT, CORN, TOMATOES, OLIVES, DATES (available)
- **Polygon drawing** - Interactive map editor:
  - Tap to add points
  - Drag to adjust
  - Minimum 3 points required
  - Visual polygon preview
- **Area calculation** - Automatic area calculation in square meters
- **Validation** - Ensures all required fields are filled

### Farm List
- **Farm listing** - Shows all user's farms
- **Farm details** - Name, type, and area display
- **Navigation** - Tap to view farm details
- **Empty state** - Helpful message when no farms exist
- **Create button** - Quick access to create new farm

### Farm Details
- **Farm information** - Name, type, area display
- **Request summary** - Shows number of requests
- **Recent requests** - Lists last 5 requests
- **Quick actions** - Navigate to requests list
- **Request status** - Visual status indicators

### Farm Management
- **Update farm** - Modify name, type, or polygon
- **Delete farm** - Remove farm and all associated requests
- **Cascade deletion** - Automatically deletes related data

## 📋 Request Management Features

### Create Request
- **Draft creation** - Creates empty draft request
- **Farm association** - Links request to specific farm
- **Auto-save** - Saves on image upload
- **Status tracking** - DRAFT status initially

### Image Upload
- **Normal images** - Regular field photos
  - Camera capture
  - GPS location tagging
  - Automatic upload
- **Macro images** - Close-up photos (10x-100x zoom)
  - Camera capture
  - GPS location tagging
  - Automatic upload
- **Image gallery** - Visual display of uploaded images
- **Image metadata** - Shows type and location
- **Multiple uploads** - Add unlimited images

### Draft Request Screen
- **Image capture buttons** - Large, accessible buttons
- **Image gallery** - Grid view of uploaded images
- **Finish button** - Navigate to summary
- **Real-time updates** - Gallery updates after upload

### Request Summary
- **Image count** - Shows normal and macro image counts
- **Expert intervention** - Checkbox option
- **Notes field** - Multi-line text input
- **Send button** - Submits request (DRAFT → PENDING)
- **Validation** - Ensures at least one image uploaded

### Request List
- **Farm-specific listing** - Shows requests for selected farm
- **Status display** - Visual status badges
- **Request navigation** - Tap to view/edit request
- **Create button** - Quick access to create new request
- **Empty state** - Helpful message when no requests exist

### Request Results (Farmer)
- **Tabbed interface** - Three views:
  1. **Map View** - Interactive map with disease markers
  2. **Disease List** - Grouped diseases with details
  3. **Report View** - Markdown report display
- **Disease markers** - Red markers on map for detected diseases
- **Disease grouping** - Diseases grouped by type
- **Treatment plans** - Detailed treatment information
- **Materials list** - Required materials and products
- **Services info** - Recommended services
- **Markdown rendering** - Formatted report display

## 👨‍💼 Admin Features

### Admin Dashboard
- **All requests view** - See all requests from all farms
- **Status filtering** - Filter by request status:
  - PENDING
  - ACCEPTED
  - PROCESSING
  - PROCESSED
  - COMPLETED
- **Request details** - Farm name, status, image counts
- **Quick navigation** - Tap to view request details
- **Refresh** - Pull-to-refresh functionality

### Request Processing
- **Accept request** - Change status PENDING → ACCEPTED
- **Process request** - Trigger AI processing (ACCEPTED → PROCESSING)
- **View images** - See all uploaded images
- **Image details** - GPS location, type, disease info
- **Status badges** - Visual status indicators

### Report Management
- **Report editor** - Markdown editor for final reports
- **Load existing report** - Pre-fills editor with current report
- **Save report** - Updates request report
- **Markdown support** - Full markdown syntax support
- **Preview** - See formatted report

### Request Completion
- **Complete request** - Mark as COMPLETED
- **Status update** - Updates request and notifies farmer
- **Final report** - Report becomes visible to farmer

### User Management
- **List all users** - View all system users
- **Create user** - Add new users (FARMER or ADMIN)
- **Update user** - Modify user details
- **Delete user** - Remove users from system
- **Role management** - Assign/change user roles

### Farm Management (Admin)
- **List all farms** - View all farms in system
- **Filter by user** - Filter farms by owner
- **Update farms** - Modify any farm
- **Delete farms** - Remove farms (with cascade)

### Request Management (Admin)
- **List all requests** - View all requests
- **Filter by status** - Filter by request status
- **Full CRUD** - Create, read, update, delete requests
- **Bulk operations** - Process multiple requests

## 🗺️ Map Features

### Polygon Editor
- **Interactive drawing** - Tap to add points
- **Point adjustment** - Drag points to reposition
- **Visual feedback** - Polygon preview
- **Area calculation** - Real-time area display
- **Minimum points** - Enforces 3+ points

### Disease Map View
- **OpenStreetMap tiles** - Free map tiles
- **Disease markers** - Red markers for detected diseases
- **GPS accuracy** - High-accuracy location
- **Zoom controls** - Pinch to zoom
- **Center on first disease** - Auto-centers map

## 📸 Image Features

### Image Capture
- **Camera integration** - Direct camera access
- **Image quality** - 85% quality for balance
- **GPS tagging** - Automatic location capture
- **Type selection** - Normal or Macro
- **Error handling** - User-friendly error messages

### Image Gallery
- **Grid layout** - 3-column grid
- **Type indicators** - Visual type indicators
- **Image count** - Shows total images
- **Responsive** - Adapts to screen size

## 📊 Reporting Features

### AI Report Generation
- **Automatic generation** - AI creates report after processing
- **Disease summary** - Overview of all detected diseases
- **Treatment recommendations** - Detailed treatment plans
- **Materials list** - Required materials
- **Services info** - Expert services needed
- **Markdown format** - Structured markdown report

### Report Display
- **Markdown rendering** - Formatted display
- **Read-only view** - Farmers view formatted report
- **Editable view** - Admins can edit reports
- **Save functionality** - Updates stored report

## 🔔 Notification Features

### User Feedback
- **Loading indicators** - Shows during operations
- **Success messages** - Confirmation snackbars
- **Error messages** - Descriptive error snackbars
- **Form validation** - Real-time validation feedback

## 🎨 UI/UX Features

### Design System
- **Bordered cards** - Clean, professional look
- **Uniform padding** - Consistent spacing
- **No shadows** - Flat design aesthetic
- **Dashboard style** - IBM-inspired design
- **Color scheme** - Professional, muted colors

### Navigation
- **GoRouter** - Type-safe navigation
- **Deep linking** - URL-based navigation
- **Back navigation** - Proper back button handling
- **Role-based menus** - Admin-specific navigation

### Responsive Design
- **Adaptive layouts** - Works on different screen sizes
- **Touch-friendly** - Large tap targets
- **Accessibility** - Proper labels and semantics

## 🔍 Search & Filter Features

### Admin Filters
- **Status filter** - Filter requests by status
- **User filter** - Filter farms by user
- **Dropdown menus** - Easy filter selection
- **Clear filters** - Reset to show all

## 📱 Mobile Features

### GPS Integration
- **Location services** - Automatic GPS access
- **Permission handling** - Requests location permission
- **High accuracy** - Precise location capture
- **Error handling** - Handles location unavailable

### Camera Integration
- **Native camera** - Direct camera access
- **Image picker** - Choose from gallery option
- **Quality settings** - Optimized image quality
- **File handling** - Proper file management

## 🔒 Security Features

### Authentication Security
- **Password hashing** - bcrypt with 10 rounds
- **JWT tokens** - Secure token-based auth
- **Token expiration** - Configurable expiration
- **Secure storage** - Encrypted local storage

### Authorization Security
- **Role-based access** - FARMER vs ADMIN
- **Resource ownership** - Users own their data
- **Admin protection** - Admin-only endpoints
- **Middleware validation** - Every request validated

### Data Security
- **Input validation** - All inputs validated
- **SQL injection prevention** - Prisma ORM protection
- **File upload security** - Type and size validation
- **CORS protection** - Restricted origins

## 📈 Analytics & Monitoring

### Request Tracking
- **Status history** - Track status changes
- **Timestamps** - Created, updated, completed dates
- **Image tracking** - Track all uploaded images
- **Processing time** - Monitor processing duration

## 🧪 Testing Features

### Test Coverage
- **55 Flutter unit tests** - All API endpoints tested
- **Backend unit tests** - Service and repository tests
- **Integration tests** - End-to-end API tests
- **Test scripts** - Automated test execution

## 🚀 Performance Features

### Optimization
- **Lazy loading** - Load data on demand
- **Image compression** - Optimized uploads
- **Efficient queries** - Database indexing
- **State caching** - Provider state persistence

## 📝 Logging Features

### Error Logging
- **Debug logging** - Development error logs
- **Error messages** - User-friendly errors
- **Stack traces** - Detailed error information
- **Request logging** - API request logging

---

**Last Updated**: 2024

