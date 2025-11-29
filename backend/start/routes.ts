/*
|--------------------------------------------------------------------------
| Routes file
|--------------------------------------------------------------------------
|
| The routes file is used for defining the HTTP routes.
|
*/

import router from '@adonisjs/core/services/router'
import { middleware } from './kernel.js'

// Import controllers
const AuthController = () => import('#controllers/auth_controller')
const FarmsController = () => import('#controllers/farms_controller')
const RequestsController = () => import('#controllers/requests_controller')
const ImagesController = () => import('#controllers/images_controller')

// Public routes
router.post('/api/auth/sign-up', [AuthController, 'signUp'])
router.post('/api/auth/sign-in', [AuthController, 'signIn'])

// Public image serving (no auth required for viewing images)
router.get('/uploads/*', [ImagesController, 'show'])

// Protected routes (require authentication)
router
  .group(() => {
    // Auth routes
    router.get('/api/auth/me', [AuthController, 'me'])

    // Farm routes
    router.get('/api/farms', [FarmsController, 'index'])
    router.post('/api/farms', [FarmsController, 'store'])
    router.get('/api/farms/:id', [FarmsController, 'show'])
    router.put('/api/farms/:id', [FarmsController, 'update'])
    router.delete('/api/farms/:id', [FarmsController, 'destroy'])

    // Request routes
    router.get('/api/requests', [RequestsController, 'index'])
    router.post('/api/requests', [RequestsController, 'store'])
    router.get('/api/requests/:id', [RequestsController, 'show'])
    router.put('/api/requests/:id', [RequestsController, 'update'])
    router.post('/api/requests/:id/images', [RequestsController, 'uploadImage'])
    router.post('/api/requests/:id/images/bulk', [RequestsController, 'bulkUploadImages'])
    router.post('/api/requests/:id/send', [RequestsController, 'send'])
    router.post('/api/requests/:id/ai-report', [RequestsController, 'generateAiReport'])
    router.get('/api/requests/:id/report', [RequestsController, 'getReport'])
    // Re-analyze a single request image
    router.post('/api/request-images/:id/reanalyze', [RequestsController, 'reanalyzeImage'])
    // Delete a single request image
    router.delete('/api/request-images/:id', [RequestsController, 'deleteImage'])
  })
  .use(middleware.auth())

// Root route
router.get('/', async () => {
  return {
    hello: 'world',
  }
})
