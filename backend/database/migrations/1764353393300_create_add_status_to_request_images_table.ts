import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'request_images'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table
        .enum('status', ['PENDING', 'UPLOADED', 'PROCESSING', 'PROCESSED', 'FAILED'])
        .notNullable()
        .defaultTo('PENDING')
        .after('type')
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('status')
    })
  }
}
