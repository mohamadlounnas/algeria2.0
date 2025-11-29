import vine from '@vinejs/vine'

export const createRequestValidator = vine.compile(
  vine.object({
    farmId: vine.string(),
  })
)

export const updateRequestValidator = vine.compile(
  vine.object({
    expertIntervention: vine.boolean().optional(),
    note: vine.string().optional(),
  })
)

export const uploadImageValidator = vine.compile(
  vine.object({
    type: vine.enum(['NORMAL', 'MACRO']),
    latitude: vine.number(),
    longitude: vine.number(),
  })
)

export const bulkUploadImagesValidator = vine.compile(
  vine.object({
    images: vine.array(
      vine.object({
        type: vine.enum(['NORMAL', 'MACRO']),
        latitude: vine.number(),
        longitude: vine.number(),
        filePath: vine.string(), // Temporary local path, will be uploaded
      })
    ),
  })
)
