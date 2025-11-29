import { DateTime } from 'luxon'
import { BaseModel, column, belongsTo } from '@adonisjs/lucid/orm'
import type { BelongsTo } from '@adonisjs/lucid/types/relations'
import User from './user.js'

export default class Farm extends BaseModel {
  @column({ isPrimary: true })
  declare id: number

  @column()
  declare userId: number

  @column()
  declare name: string

  @column()
  declare type: 'GRAPES' | 'WHEAT' | 'CORN' | 'TOMATOES' | 'OLIVES' | 'DATES'

  @column({
    prepare: (value: Array<{ latitude: number; longitude: number }>) => JSON.stringify(value),
    consume: (value: string) => JSON.parse(value),
  })
  declare polygon: Array<{ latitude: number; longitude: number }>

  @column()
  declare area: number

  @belongsTo(() => User)
  declare user: BelongsTo<typeof User>

  @column.dateTime({ autoCreate: true })
  declare createdAt: DateTime

  @column.dateTime({ autoCreate: true, autoUpdate: true })
  declare updatedAt: DateTime | null
}
