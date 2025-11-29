import type { HttpContext } from '@adonisjs/core/http'
import app from '@adonisjs/core/services/app'
import Request from '#models/request'
import RequestImage from '#models/request_image'
import Farm from '#models/farm'
import {
  createRequestValidator,
  updateRequestValidator,
  uploadImageValidator,
  bulkUploadImagesValidator,
} from '#validators/request'
import { randomBytes } from 'node:crypto'
import { join } from 'node:path'
import { existsSync, mkdirSync, copyFileSync, unlinkSync } from 'node:fs'

export default class RequestsController {
  /**
   * Get requests - For farmers: filtered by farmId, For admins: all requests
   */
  async index({ auth, request, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const farmId = request.qs().farmId as string | undefined

    let query = Request.query().preload('images').preload('farm')

    // Farmers can only see their own requests
    if (user.role === 'FARMER') {
      if (!farmId) {
        return response.status(400).json({
          message: 'farmId is required for farmers',
        })
      }

      // Verify farm belongs to user
      const farm = await Farm.find(farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to access this farm',
        })
      }

      query = query.where('farm_id', farmId)
    }
    // Admins can see all requests, optionally filtered
    else if (user.role === 'ADMIN') {
      if (farmId) {
        query = query.where('farm_id', farmId)
      }
    }

    const requests = await query.orderBy('created_at', 'desc')

    return response.json(
      requests.map((req) => ({
        id: req.id.toString(),
        farmId: req.farmId.toString(),
        status: req.status,
        expertIntervention: req.expertIntervention,
        note: req.note,
        finalReport: req.finalReport,
        createdAt: req.createdAt.toISO(),
        updatedAt: req.updatedAt?.toISO() || null,
        completedAt: req.completedAt?.toISO() || null,
      }))
    )
  }

  /**
   * Create a new draft request
   */
  async store({ request, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const data = await request.validateUsing(createRequestValidator)

    // Verify farm belongs to user
    const farm = await Farm.find(data.farmId)
    if (!farm || farm.userId !== user.id) {
      return response.status(403).json({
        message: 'You do not have permission to create requests for this farm',
      })
    }

    const newRequest = await Request.create({
      farmId: parseInt(data.farmId),
      status: 'DRAFT',
      expertIntervention: false,
      note: null,
      finalReport: null,
    })

    return response.json({
      id: newRequest.id.toString(),
      farmId: newRequest.farmId.toString(),
      status: newRequest.status,
      expertIntervention: newRequest.expertIntervention,
      note: newRequest.note,
      finalReport: newRequest.finalReport,
      createdAt: newRequest.createdAt.toISO(),
      updatedAt: newRequest.updatedAt?.toISO() || null,
      completedAt: newRequest.completedAt,
    })
  }

  /**
   * Get request by ID with all images
   */
  async show({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.query()
      .where('id', requestId)
      .preload('images')
      .preload('farm')
      .firstOrFail()

    // Verify access: farmers can only see their own requests
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to access this request',
        })
      }
    }

    return response.json({
      id: req.id.toString(),
      farmId: req.farmId.toString(),
      status: req.status,
      expertIntervention: req.expertIntervention,
      note: req.note,
      finalReport: req.finalReport,
      images: req.images.map((img) => ({
        id: img.id.toString(),
        requestId: img.requestId.toString(),
        type: img.type,
        status: img.status,
        filePath: img.filePath, // Relative path, can be used as URL: /uploads/request-images/xxx.jpg
        latitude: img.latitude,
        longitude: img.longitude,
        diseaseType: img.diseaseType,
        confidence: img.confidence,
        treatmentPlan: img.treatmentPlan,
        materials: img.materials,
        services: img.services,
        createdAt: img.createdAt.toISO(),
        processedAt: img.processedAt?.toISO() || null,
      })),
      createdAt: req.createdAt.toISO(),
      updatedAt: req.updatedAt?.toISO() || null,
      completedAt: req.completedAt?.toISO() || null,
    })
  }

  /**
   * Update request metadata
   */
  async update({ params, request, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.findOrFail(requestId)

    // Verify access
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to update this request',
        })
      }
      // Farmers can only update DRAFT requests
      if (req.status !== 'DRAFT') {
        return response.status(400).json({
          message: 'Only draft requests can be updated',
        })
      }
    }

    const data = await request.validateUsing(updateRequestValidator)

    if (data.expertIntervention !== undefined) {
      req.expertIntervention = data.expertIntervention
    }
    if (data.note !== undefined) {
      req.note = data.note
    }

    await req.save()

    return response.json({
      id: req.id.toString(),
      farmId: req.farmId.toString(),
      status: req.status,
      expertIntervention: req.expertIntervention,
      note: req.note,
      finalReport: req.finalReport,
      createdAt: req.createdAt.toISO(),
      updatedAt: req.updatedAt?.toISO() || null,
      completedAt: req.completedAt?.toISO() || null,
    })
  }

  /**
   * Upload a single image to a request (draft mode)
   */
  async uploadImage({ params, request, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.findOrFail(requestId)

    // Verify access
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to upload images to this request',
        })
      }
      // Farmers can only upload to DRAFT requests
      if (req.status !== 'DRAFT') {
        return response.status(400).json({
          message: 'Images can only be uploaded to draft requests',
        })
      }
    }

    // Validate form data
    const data = await request.validateUsing(uploadImageValidator)

    // Get uploaded file
    const file = request.file('file', {
      size: '10mb',
      extnames: ['jpg', 'jpeg', 'png'],
    })

    if (!file) {
      return response.status(400).json({
        message: 'Image file is required',
      })
    }

    // Generate unique filename
    const uploadsDir = app.tmpPath('uploads/request-images')
    if (!existsSync(uploadsDir)) {
      mkdirSync(uploadsDir, { recursive: true })
    }

    const fileExtension = file.extname || 'jpg'
    const fileName = `${randomBytes(16).toString('hex')}.${fileExtension}`
    const filePath = join(uploadsDir, fileName)

    // Move file to uploads directory
    await file.move(uploadsDir, { name: fileName })

    // Create image record (store relative path for URL access)
    const image = await RequestImage.create({
      requestId: req.id,
      type: data.type,
      status: 'UPLOADED', // Image is uploaded and ready
      filePath: `uploads/request-images/${fileName}`, // Relative path for URL
      latitude: data.latitude,
      longitude: data.longitude,
      diseaseType: null,
      confidence: null,
      treatmentPlan: null,
      materials: null,
      services: null,
      processedAt: null,
    })

    // Auto-save request (update timestamp)
    await req.save()

    return response.json({
      id: image.id.toString(),
      requestId: image.requestId.toString(),
      type: image.type,
      status: image.status,
      filePath: image.filePath,
      latitude: image.latitude,
      longitude: image.longitude,
      diseaseType: image.diseaseType,
      confidence: image.confidence,
      treatmentPlan: image.treatmentPlan,
      materials: image.materials,
      services: image.services,
      createdAt: image.createdAt.toISO(),
      processedAt: image.processedAt,
    })
  }

  /**
   * Bulk upload images (for offline mode)
   */
  async bulkUploadImages({ params, request, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.findOrFail(requestId)

    // Verify access
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to upload images to this request',
        })
      }
      // Farmers can only upload to DRAFT requests
      if (req.status !== 'DRAFT') {
        return response.status(400).json({
          message: 'Images can only be uploaded to draft requests',
        })
      }
    }

    // Get all uploaded files
    const files = request.files('files', {
      size: '10mb',
      extnames: ['jpg', 'jpeg', 'png'],
    })

    if (!files || files.length === 0) {
      return response.status(400).json({
        message: 'At least one image file is required',
      })
    }

    // Get metadata from request body (can be JSON string in form field or direct JSON)
    const body = request.body()
    let imagesMetadata: Array<{
      type: 'NORMAL' | 'MACRO'
      latitude: number
      longitude: number
    }>

    // Handle both JSON string and direct object
    if (typeof body.images === 'string') {
      try {
        imagesMetadata = JSON.parse(body.images)
      } catch (e) {
        return response.status(400).json({
          message: 'Invalid images metadata format',
        })
      }
    } else if (Array.isArray(body.images)) {
      imagesMetadata = body.images
    } else {
      return response.status(400).json({
        message: 'Images metadata is required',
      })
    }

    if (!imagesMetadata || imagesMetadata.length !== files.length) {
      return response.status(400).json({
        message: `Number of files (${files.length}) must match number of image metadata entries (${imagesMetadata?.length || 0})`,
      })
    }

    const uploadsDir = app.tmpPath('uploads/request-images')
    if (!existsSync(uploadsDir)) {
      mkdirSync(uploadsDir, { recursive: true })
    }

    const uploadedImages = []

    // Process each file
    for (let i = 0; i < files.length; i++) {
      const file = files[i]
      const metadata = imagesMetadata[i]

      // Generate unique filename
      const fileExtension = file.extname || 'jpg'
      const fileName = `${randomBytes(16).toString('hex')}.${fileExtension}`
      const filePath = join(uploadsDir, fileName)

      // Move file to uploads directory
      await file.move(uploadsDir, { name: fileName })

      // Create image record (store relative path for URL access)
      const image = await RequestImage.create({
        requestId: req.id,
        type: metadata.type,
        status: 'UPLOADED',
        filePath: `uploads/request-images/${fileName}`, // Relative path for URL
        latitude: metadata.latitude,
        longitude: metadata.longitude,
        diseaseType: null,
        confidence: null,
        treatmentPlan: null,
        materials: null,
        services: null,
        processedAt: null,
      })

      uploadedImages.push({
        id: image.id.toString(),
        requestId: image.requestId.toString(),
        type: image.type,
        status: image.status,
        filePath: image.filePath,
        latitude: image.latitude,
        longitude: image.longitude,
        diseaseType: image.diseaseType,
        confidence: image.confidence,
        treatmentPlan: image.treatmentPlan,
        materials: image.materials,
        services: image.services,
        createdAt: image.createdAt.toISO(),
        processedAt: image.processedAt,
      })
    }

    // Auto-save request
    await req.save()

    return response.json({
      success: true,
      images: uploadedImages,
      count: uploadedImages.length,
    })
  }

  /**
   * Send request (change status from DRAFT to PENDING)
   */
  async send({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.findOrFail(requestId)

    // Verify access
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to send this request',
        })
      }
    }

    // Only DRAFT requests can be sent
    if (req.status !== 'DRAFT') {
      return response.status(400).json({
        message: 'Only draft requests can be sent',
      })
    }

    // Check if request has at least one image
    const imageCount = await RequestImage.query()
      .where('request_id', req.id)
      .where('status', 'UPLOADED')
      .count('* as total')

    if (imageCount[0].$extras.total === 0) {
      return response.status(400).json({
        message: 'Request must have at least one uploaded image before sending',
      })
    }

    req.status = 'PENDING'
    await req.save()

    return response.json({
      id: req.id.toString(),
      farmId: req.farmId.toString(),
      status: req.status,
      expertIntervention: req.expertIntervention,
      note: req.note,
      finalReport: req.finalReport,
      createdAt: req.createdAt.toISO(),
      updatedAt: req.updatedAt?.toISO() || null,
      completedAt: req.completedAt?.toISO() || null,
    })
  }

  /**
   * Get request report (markdown)
   */
  async getReport({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.findOrFail(requestId)

    // Verify access
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to access this report',
        })
      }
    }

    return response.json({
      report: req.finalReport,
    })
  }
}
