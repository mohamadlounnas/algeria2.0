import type { HttpContext } from '@adonisjs/core/http'
import app from '@adonisjs/core/services/app'
import Request from '#models/request'
import RequestImage from '#models/request_image'
import Farm from '#models/farm'
import { DateTime } from 'luxon'
import {
  createRequestValidator,
  updateRequestValidator,
  uploadImageValidator,
  bulkUploadImagesValidator,
} from '#validators/request'
import { randomBytes } from 'node:crypto'
import { join } from 'node:path'
import { existsSync, mkdirSync, copyFileSync, unlinkSync } from 'node:fs'
import env from '#start/env'
import { buildAiReport } from '#utils/ai_report_agent'

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
      farmId: Number.parseInt(data.farmId),
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
        imageUrl: img.imageUrl,
        heatmapUrl: img.heatmapUrl,
        overlayUrl: img.overlayUrl,
        anomalyScore: img.anomalyScore,
        isDiseased: img.isDiseased,
        diseasesJson: img.diseasesJson,
        leafsData: img.leafsData,
        summaryJson: img.summaryJson,
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
    let image = await RequestImage.create({
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
      imageUrl: null,
      heatmapUrl: null,
      overlayUrl: null,
      anomalyScore: null,
      isDiseased: null,
      diseasesJson: null,
      processedAt: null,
    })

    // Trigger AI processing
    try {
      // Construct public URL to the uploaded image served by backend
      // Use PUBLIC_BASE_URL if provided (e.g. http://127.0.0.1:3333),
      // fallback to 127.0.0.1 to avoid using 0.0.0.0 which is not routable.
      const port = env.get('PORT')
      const baseUrl = env.get('PUBLIC_BASE_URL') || `http://127.0.0.1:${port}`
      const publicImageUrl = `${baseUrl}/${image.filePath}`

      // Model server URL (from env or default localhost:8888)
      const modelBaseUrl = env.get('AI_MODEL_URL') || 'http://127.0.0.1:8888'
      const modelUrl = `${modelBaseUrl}/api/process?url=${encodeURIComponent(publicImageUrl)}`

      // Update status to PROCESSING
      image.status = 'PROCESSING'
      await image.save()

      const res = await fetch(modelUrl, { method: 'GET' })
      if (!res.ok) throw new Error(`Model server error: ${res.status}`)
      const payload = (await res.json()) as any

      // Only keep diseased leafs
      const leafs = Array.isArray(payload?.leafs)
        ? payload.leafs //.filter((l: any) => l?.is_diseased === true)
        : []

      // Calculate summary from leafs array
      const summary =
        leafs.length > 0
          ? {
              total_leafs: leafs.length,
              diseased_leafs: leafs.length,
              healthy_leafs: 0,
            }
          : null

      const first = leafs.length > 0 ? leafs[0] : null

      if (first) {
        // Store complete leafs array
        image.leafsData = JSON.stringify(leafs)

        // Store summary data
        image.summaryJson = summary ? JSON.stringify(summary) : null

        // Keep first leaf data in legacy fields for backward compatibility
        image.imageUrl = typeof first.image === 'string' ? first.image : null
        image.heatmapUrl = typeof first.heatmap === 'string' ? first.heatmap : null
        image.overlayUrl = typeof first.overlay === 'string' ? first.overlay : null
        image.anomalyScore = typeof first.anomaly_score === 'number' ? first.anomaly_score : null
        image.isDiseased = typeof first.is_diseased === 'boolean' ? first.is_diseased : null
        // store diseases object as JSON string
        image.diseasesJson = first.diseases ? JSON.stringify(first.diseases) : null

        // Derive quick fields
        if (first.diseases && Object.keys(first.diseases).length > 0) {
          const [name, detail] = Object.entries(first.diseases)[0] as [string, any]
          image.diseaseType = name
          image.confidence = typeof detail?.confidence === 'number' ? detail.confidence : null
          image.treatmentPlan = typeof detail?.treatment === 'string' ? detail.treatment : null
        }

        image.status = 'PROCESSED'
        image.processedAt = DateTime.now()
        await image.save()
      } else {
        // No leaf detected; mark as FAILED
        image.status = 'FAILED'
        await image.save()
      }
    } catch (err) {
      // Mark image as FAILED on error
      try {
        image.status = 'FAILED'
        await image.save()
      } catch {}
      console.error('AI processing failed:', err)
    }

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
      imageUrl: image.imageUrl,
      heatmapUrl: image.heatmapUrl,
      overlayUrl: image.overlayUrl,
      anomalyScore: image.anomalyScore,
      isDiseased: image.isDiseased,
      diseasesJson: image.diseasesJson,
      leafsData: image.leafsData,
      summaryJson: image.summaryJson,
      createdAt: image.createdAt.toISO(),
      processedAt: image.processedAt?.toISO() || null,
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
    for (const [i, file] of files.entries()) {
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
        imageUrl: null,
        heatmapUrl: null,
        overlayUrl: null,
        anomalyScore: null,
        isDiseased: null,
        diseasesJson: null,
        leafsData: null,
        summaryJson: null,
        createdAt: image.createdAt.toISO(),
        processedAt: image.processedAt?.toISO() || null,
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

    // Check if request has at least one image (any uploaded, processing, or processed image)
    const imageCount = await RequestImage.query()
      .where('request_id', req.id)
      .whereIn('status', ['UPLOADED', 'PROCESSING', 'PROCESSED'])
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
   * Generate an AI markdown report based on processed images
   */
  async generateAiReport({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const requestId = params.id

    const req = await Request.query()
      .where('id', requestId)
      .preload('images')
      .preload('farm')
      .firstOrFail()

    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to access this request',
        })
      }
    }

    const report = buildAiReport(req)
    req.finalReport = report
    await req.save()

    return response.json({
      report,
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

  /**
   * Re-run AI analysis on a single image
   */
  async reanalyzeImage({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const imageId = params.id

    // Load image and its parent request
    const image = await RequestImage.findOrFail(imageId)
    const req = await Request.findOrFail(image.requestId)

    // Access control: farmers can only act on their own farms
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to reanalyze this image',
        })
      }
    }

    // Build public URL for the stored image
    const port = env.get('PORT')
    const baseUrl = env.get('PUBLIC_BASE_URL') || `http://127.0.0.1:${port}`
    const publicImageUrl = `${baseUrl}/${image.filePath}`

    // Call model
    const modelBaseUrl = env.get('AI_MODEL_URL') || 'http://127.0.0.1:8888'
    const modelUrl = `${modelBaseUrl}/api/process?url=${encodeURIComponent(publicImageUrl)}`

    // Update to PROCESSING
    image.status = 'PROCESSING'
    await image.save()

    try {
      const res = await fetch(modelUrl)
      if (!res.ok) throw new Error(`Model server error: ${res.status}`)
      const payload = (await res.json()) as any

      // Only keep diseased leafs
      const leafs = Array.isArray(payload?.leafs)
        ? payload.leafs.filter((l: any) => l?.is_diseased === true)
        : []

      // Calculate summary from leafs array
      const summary =
        leafs.length > 0
          ? {
              total_leafs: leafs.length,
              diseased_leafs: leafs.length,
              healthy_leafs: 0,
            }
          : null

      const first = leafs.length > 0 ? leafs[0] : null

      // Reset derived fields first
      image.imageUrl = null
      image.heatmapUrl = null
      image.overlayUrl = null
      image.anomalyScore = null
      image.isDiseased = null
      image.diseasesJson = null
      image.leafsData = null
      image.summaryJson = null
      image.diseaseType = null
      image.confidence = null
      image.treatmentPlan = null

      if (first) {
        // Store complete leafs array
        image.leafsData = JSON.stringify(leafs)

        // Store summary data
        image.summaryJson = summary ? JSON.stringify(summary) : null

        image.imageUrl = typeof first.image === 'string' ? first.image : null
        image.heatmapUrl = typeof first.heatmap === 'string' ? first.heatmap : null
        image.overlayUrl = typeof first.overlay === 'string' ? first.overlay : null
        image.anomalyScore = typeof first.anomaly_score === 'number' ? first.anomaly_score : null
        image.isDiseased = typeof first.is_diseased === 'boolean' ? first.is_diseased : null
        image.diseasesJson = first.diseases ? JSON.stringify(first.diseases) : null

        if (first.diseases && Object.keys(first.diseases).length > 0) {
          const [name, detail] = Object.entries(first.diseases)[0] as [string, any]
          image.diseaseType = name
          image.confidence = typeof detail?.confidence === 'number' ? detail.confidence : null
          image.treatmentPlan = typeof detail?.treatment === 'string' ? detail.treatment : null
        }

        image.status = 'PROCESSED'
        image.processedAt = DateTime.now()
      } else {
        image.status = 'FAILED'
      }

      await image.save()

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
        imageUrl: image.imageUrl,
        heatmapUrl: image.heatmapUrl,
        overlayUrl: image.overlayUrl,
        anomalyScore: image.anomalyScore,
        isDiseased: image.isDiseased,
        diseasesJson: image.diseasesJson,
        leafsData: image.leafsData,
        summaryJson: image.summaryJson,
        createdAt: image.createdAt.toISO(),
        processedAt: image.processedAt?.toISO() || null,
      })
    } catch (err) {
      image.status = 'FAILED'
      await image.save()
      return response.status(502).json({ message: 'AI processing failed' })
    }
  }

  /**
   * Delete an image from a request
   */
  async deleteImage({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const imageId = params.id

    const image = await RequestImage.findOrFail(imageId)
    const req = await Request.findOrFail(image.requestId)

    // Access control
    if (user.role === 'FARMER') {
      const farm = await Farm.find(req.farmId)
      if (!farm || farm.userId !== user.id) {
        return response.status(403).json({
          message: 'You do not have permission to delete this image',
        })
      }
      // Farmers can only delete from DRAFT requests
      if (req.status !== 'DRAFT') {
        return response.status(400).json({
          message: 'Images can only be deleted from draft requests',
        })
      }
    }

    // Remove file from disk if exists
    try {
      const absolutePath = app.tmpPath(image.filePath)
      if (existsSync(absolutePath)) {
        unlinkSync(absolutePath)
      }
    } catch {}

    await image.delete()
    await req.save()

    return response.json({ success: true })
  }
}
