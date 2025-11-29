import vine from '@vinejs/vine'

const coordinateSchema = vine.object({
  latitude: vine.number(),
  longitude: vine.number(),
})

export const createFarmValidator = vine.compile(
  vine.object({
    name: vine.string().minLength(1),
    type: vine.enum(['GRAPES', 'WHEAT', 'CORN', 'TOMATOES', 'OLIVES', 'DATES']),
    polygon: vine.array(coordinateSchema).minLength(3),
  })
)

export const updateFarmValidator = vine.compile(
  vine.object({
    name: vine.string().minLength(1).optional(),
    type: vine.enum(['GRAPES', 'WHEAT', 'CORN', 'TOMATOES', 'OLIVES', 'DATES']).optional(),
    polygon: vine.array(coordinateSchema).minLength(3).optional(),
  })
)
