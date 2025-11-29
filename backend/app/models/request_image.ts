import { DateTime } from 'luxon'
import { BaseModel, column, belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import Request from './request.js'

export default class RequestImage extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare requestId: number

  @column()
  declare type: 'NORMAL' | 'MACRO'

  @column()
  declare status: 'PENDING' | 'UPLOADED' | 'PROCESSING' | 'PROCESSED' | 'FAILED'

  @column()
  declare filePath: string

  @column()
  declare latitude: number

  @column()
  declare longitude: number

  @column()
  declare diseaseType: string | null

  @column()
  declare confidence: number | null

  @column()
  declare treatmentPlan: string | null

  @column()
  declare materials: string | null

  @column()
  declare services: string | null

  @belongsTo(() => Request)
  declare request: BelongsTo<typeof Request>

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime()
  declare processedAt: DateTime | null
}
