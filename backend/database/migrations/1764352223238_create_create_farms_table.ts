import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'farms'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').notNullable()
      table
        .integer('user_id')
        .notNullable()
        .unsigned()
        .references('id')
        .inTable('users')
        .onDelete('CASCADE')
      table.string('name').notNullable()
      table.enum('type', ['GRAPES', 'WHEAT', 'CORN', 'TOMATOES', 'OLIVES', 'DATES']).notNullable()
      table.text('polygon').notNullable() // JSON array of {latitude, longitude}
      table.decimal('area', 10, 2).notNullable() // Area in square meters

      table.timestamp('created_at').notNullable()
      table.timestamp('updated_at').nullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
