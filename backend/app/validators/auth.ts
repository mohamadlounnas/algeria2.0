import vine from '@vinejs/vine'

export const signUpValidator = vine.compile(
  vine.object({
    email: vine.string().email(),
    password: vine.string().minLength(8),
    name: vine.string().minLength(1),
    role: vine.enum(['FARMER', 'ADMIN']).optional(),
  })
)

export const signInValidator = vine.compile(
  vine.object({
    email: vine.string().email(),
    password: vine.string(),
  })
)
