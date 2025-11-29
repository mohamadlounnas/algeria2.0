import type { HttpContext } from '@adonisjs/core/http'
import Farm from '#models/farm'
import { createFarmValidator, updateFarmValidator } from '#validators/farm'
import { calculatePolygonArea } from '../utils/polygon_calculator.js'

export default class FarmsController {
  /**
   * Get all farms for the authenticated user
   */
  async index({ auth, response }: HttpContext) {
    const user = auth.getUserOrFail()

    const farms = await Farm.query().where('user_id', user.id).orderBy('created_at', 'desc')

    return response.json(
      farms.map((farm) => ({
        id: farm.id.toString(),
        userId: farm.userId.toString(),
        name: farm.name,
        type: farm.type,
        polygon: farm.polygon,
        area: farm.area,
        createdAt: farm.createdAt.toISO(),
        updatedAt: farm.updatedAt?.toISO() || null,
      }))
    )
  }

  /**
   * Create a new farm
   */
  async store({ request, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const data = await request.validateUsing(createFarmValidator)

    // Calculate area from polygon
    const area = calculatePolygonArea(data.polygon)

    const farm = await Farm.create({
      userId: user.id,
      name: data.name,
      type: data.type,
      polygon: data.polygon,
      area: area,
    })

    return response.json({
      id: farm.id.toString(),
      userId: farm.userId.toString(),
      name: farm.name,
      type: farm.type,
      polygon: farm.polygon,
      area: farm.area,
      createdAt: farm.createdAt.toISO(),
      updatedAt: farm.updatedAt?.toISO() || null,
    })
  }

  /**
   * Get farm by ID
   */
  async show({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const farmId = params.id

    const farm = await Farm.findOrFail(farmId)

    // Check if user owns the farm
    if (farm.userId !== user.id) {
      return response.status(403).json({
        message: 'You do not have permission to access this farm',
      })
    }

    return response.json({
      id: farm.id.toString(),
      userId: farm.userId.toString(),
      name: farm.name,
      type: farm.type,
      polygon: farm.polygon,
      area: farm.area,
      createdAt: farm.createdAt.toISO(),
      updatedAt: farm.updatedAt?.toISO() || null,
    })
  }

  /**
   * Update farm
   */
  async update({ params, request, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const farmId = params.id

    const farm = await Farm.findOrFail(farmId)

    // Check if user owns the farm
    if (farm.userId !== user.id) {
      return response.status(403).json({
        message: 'You do not have permission to update this farm',
      })
    }

    const data = await request.validateUsing(updateFarmValidator)

    // Update farm fields
    if (data.name !== undefined) {
      farm.name = data.name
    }
    if (data.type !== undefined) {
      farm.type = data.type
    }
    if (data.polygon !== undefined) {
      farm.polygon = data.polygon
      // Recalculate area if polygon is updated
      farm.area = calculatePolygonArea(data.polygon)
    }

    await farm.save()

    return response.json({
      id: farm.id.toString(),
      userId: farm.userId.toString(),
      name: farm.name,
      type: farm.type,
      polygon: farm.polygon,
      area: farm.area,
      createdAt: farm.createdAt.toISO(),
      updatedAt: farm.updatedAt?.toISO() || null,
    })
  }

  /**
   * Delete farm
   */
  async destroy({ params, auth, response }: HttpContext) {
    const user = auth.getUserOrFail()
    const farmId = params.id

    const farm = await Farm.findOrFail(farmId)

    // Check if user owns the farm
    if (farm.userId !== user.id) {
      return response.status(403).json({
        message: 'You do not have permission to delete this farm',
      })
    }

    await farm.delete()

    return response.json({
      success: true,
    })
  }
}
