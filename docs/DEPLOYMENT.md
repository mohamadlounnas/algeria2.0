# Deployment Guide

## Overview

This guide covers deployment of both the Flutter mobile app and ElysiaJS backend server.

## Backend Deployment

### Prerequisites
- Bun runtime installed
- Database (SQLite for development, PostgreSQL recommended for production)
- Environment variables configured

### Production Environment Variables

Create `.env` file:
```bash
DATABASE_URL="postgresql://user:password@host:5432/dbname"
JWT_SECRET="your-secret-key-min-32-chars"
GEMINI_API_KEY="your-gemini-api-key"
PORT=3000
NODE_ENV=production
```

### Database Setup

**For PostgreSQL:**
```bash
# Update DATABASE_URL in .env
DATABASE_URL="postgresql://user:password@host:5432/dbname"

# Run migrations
bunx prisma migrate deploy

# Generate Prisma client
bunx prisma generate
```

### Build and Run

```bash
# Install dependencies
bun install

# Generate Prisma client
bunx prisma generate

# Run migrations
bunx prisma migrate deploy

# Start server
bun run src/index.ts
```

### Using PM2 (Process Manager)

```bash
# Install PM2
npm install -g pm2

# Start server
pm2 start bun --name "dowa-api" -- run src/index.ts

# Save PM2 configuration
pm2 save

# Setup auto-restart on reboot
pm2 startup
```

### Docker Deployment

Create `Dockerfile`:
```dockerfile
FROM oven/bun:latest

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install

COPY . .

RUN bunx prisma generate

EXPOSE 3000

CMD ["bun", "run", "src/index.ts"]
```

Build and run:
```bash
docker build -t dowa-api .
docker run -p 3000:3000 --env-file .env dowa-api
```

### Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## Frontend Deployment

### Android Build

```bash
cd app

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS Build

```bash
cd app

# Build iOS
flutter build ios --release

# Archive in Xcode
# Product > Archive > Distribute App
```

### Web Build

```bash
cd app

# Build web
flutter build web --release

# Deploy to hosting (Firebase, Netlify, etc.)
```

### Environment Configuration

Update API base URL in `app/lib/core/constants/api_constants.dart`:
```dart
class ApiConstants {
  static const String baseUrl = 'https://api.yourdomain.com';
  // ...
}
```

## File Storage

### Local Storage (Development)
Images stored in `server/uploads/` directory.

### Cloud Storage (Production)

**Option 1: AWS S3**
```typescript
// Update image.service.ts to use S3
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

const s3Client = new S3Client({ region: 'us-east-1' });
```

**Option 2: Cloudinary**
```typescript
import { v2 as cloudinary } from 'cloudinary';

cloudinary.config({
  cloud_name: 'your-cloud-name',
  api_key: 'your-api-key',
  api_secret: 'your-api-secret'
});
```

## Security Checklist

### Backend
- [ ] Strong JWT_SECRET (32+ characters)
- [ ] HTTPS enabled
- [ ] CORS configured for specific origins
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (Prisma)
- [ ] File upload size limits
- [ ] Error messages don't leak sensitive info

### Frontend
- [ ] API base URL configured
- [ ] Token stored securely
- [ ] HTTPS for API calls
- [ ] Certificate pinning (optional)
- [ ] Obfuscation for release builds

## Monitoring

### Logging
- Setup logging service (Winston, Pino)
- Log errors, requests, and important events
- Rotate logs regularly

### Health Checks
```typescript
// Add health check endpoint
.get('/health', () => ({
  status: 'ok',
  timestamp: new Date().toISOString(),
  uptime: process.uptime()
}))
```

### Error Tracking
- Integrate Sentry or similar
- Track errors in production
- Alert on critical errors

## Backup Strategy

### Database Backups
```bash
# SQLite backup
cp prisma/dev.db prisma/backup-$(date +%Y%m%d).db

# PostgreSQL backup
pg_dump -U user -d dbname > backup.sql
```

### File Backups
- Backup `uploads/` directory regularly
- Consider cloud storage for redundancy

## Scaling Considerations

### Horizontal Scaling
- Use load balancer (Nginx, HAProxy)
- Multiple server instances
- Shared database
- Shared file storage (S3, etc.)

### Database Scaling
- Read replicas for read-heavy workloads
- Connection pooling
- Query optimization
- Indexing strategy

### Caching
- Redis for session storage
- Cache frequently accessed data
- CDN for static assets

## Performance Optimization

### Backend
- Enable compression (gzip)
- Database query optimization
- Connection pooling
- Async processing for heavy operations

### Frontend
- Code splitting
- Image optimization
- Lazy loading
- Bundle size optimization

## SSL/TLS Setup

### Using Let's Encrypt
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d api.yourdomain.com
```

### Update Nginx Config
```nginx
server {
    listen 443 ssl;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    # ... rest of config
}
```

## CI/CD Pipeline

### GitHub Actions Example

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: oven-sh/setup-bun@v1
      - run: bun install
      - run: bunx prisma generate
      - run: bunx prisma migrate deploy
      - run: pm2 restart dowa-api
```

## Troubleshooting

### Common Issues

**Database connection errors:**
- Check DATABASE_URL format
- Verify database is running
- Check network connectivity

**JWT errors:**
- Verify JWT_SECRET is set
- Check token expiration
- Ensure token format is correct

**File upload errors:**
- Check uploads directory permissions
- Verify disk space
- Check file size limits

**CORS errors:**
- Verify CORS origins in config
- Check preflight requests
- Ensure headers are correct

---

**Last Updated**: 2024

