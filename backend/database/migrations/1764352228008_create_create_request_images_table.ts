import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'request_images'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').notNullable()
      table
        .integer('request_id')
        .notNullable()
        .unsigned()
        .references('id')
        .inTable('requests')
        .onDelete('CASCADE')
      table.enum('type', ['NORMAL', 'MACRO']).notNullable()
      table.string('file_path').notNullable()
      table.decimal('latitude', 10, 8).notNullable()
      table.decimal('longitude', 11, 8).notNullable()
      table.string('disease_type').nullable()
      table.decimal('confidence', 5, 4).nullable() // 0.0 to 1.0
      table.text('treatment_plan').nullable()
      table.text('materials').nullable()
      table.text('services').nullable()

      table.timestamp('created_at').notNullable()
      table.timestamp('processed_at').nullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
