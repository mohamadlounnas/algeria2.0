import { DateTime } from 'luxon'
import { BaseModel, column, belongsTo, hasMany } from '@adonisjs/lucid/orm'
import type { BelongsTo, HasMany } from '@adonisjs/lucid/types/relations'
import Farm from './farm.js'
import RequestImage from './request_image.js'

export default class Request extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare farmId: number

  @column()
  declare status: 'DRAFT' | 'PENDING' | 'ACCEPTED' | 'PROCESSING' | 'PROCESSED' | 'COMPLETED'

  @column()
  declare expertIntervention: boolean

  @column()
  declare note: string | null

  @column()
  declare finalReport: string | null

  @belongsTo(() => Farm)
  declare farm: BelongsTo<typeof Farm>

  @hasMany(() => RequestImage)
  declare images: HasMany<typeof RequestImage>

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null

  @column.dateTime()
  declare completedAt: DateTime | null
}
