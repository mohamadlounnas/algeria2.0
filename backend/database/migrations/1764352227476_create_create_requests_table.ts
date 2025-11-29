import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'requests'

  async up() {
    this.schema.createTable(this.tableName, (table) => {
      table.increments('id').notNullable()
      table
        .integer('farm_id')
        .notNullable()
        .unsigned()
        .references('id')
        .inTable('farms')
        .onDelete('CASCADE')
      table
        .enum('status', ['DRAFT', 'PENDING', 'ACCEPTED', 'PROCESSING', 'PROCESSED', 'COMPLETED'])
        .notNullable()
        .defaultTo('DRAFT')
      table.boolean('expert_intervention').notNullable().defaultTo(false)
      table.text('note').nullable()
      table.text('final_report').nullable() // Markdown report

      table.timestamp('created_at').notNullable()
      table.timestamp('updated_at').nullable()
      table.timestamp('completed_at').nullable()
    })
  }

  async down() {
    this.schema.dropTable(this.tableName)
  }
}
