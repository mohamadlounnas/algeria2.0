import type { HttpContext } from '@adonisjs/core/http'
import app from '@adonisjs/core/services/app'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { existsSync } from 'node:fs'

/**
 * Controller to serve uploaded images
 */
export default class ImagesController {
  /**
   * Serve an uploaded image file
   */
  async show({ params, response }: HttpContext) {
    const wildcard = params['*'] as string | string[]
    const filePath = Array.isArray(wildcard) ? wildcard.join('/') : wildcard

    if (typeof filePath !== 'string') {
      return response.status(400).json({ message: 'Invalid file path' })
    }

    // Security: prevent directory traversal
    if (filePath.includes('..') || filePath.startsWith('/')) {
      return response.status(403).json({
        message: 'Invalid file path',
      })
    }

    // Construct full path
    // Route is /uploads/* so the wildcard omits the leading "uploads/"
    const fullPath = join(app.tmpPath(), 'uploads', filePath)

    // Verify file exists
    if (!existsSync(fullPath)) {
      return response.status(404).json({
        message: 'Image not found',
      })
    }

    // Determine content type
    const ext = filePath.split('.').pop()?.toLowerCase()
    let contentType = 'image/jpeg'
    if (ext === 'png') {
      contentType = 'image/png'
    } else if (ext === 'jpg' || ext === 'jpeg') {
      contentType = 'image/jpeg'
    }

    // Read and return file
    const fileBuffer = readFileSync(fullPath)
    return response.type(contentType).send(fileBuffer)
  }
}
