import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'request_images'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      table.string('image_url').nullable()
      table.string('heatmap_url').nullable()
      table.string('overlay_url').nullable()
      table.decimal('anomaly_score', 7, 3).nullable()
      table.boolean('is_diseased').nullable()
      table.text('diseases_json').nullable()
      table.enum('status', ['PENDING', 'UPLOADED', 'PROCESSING', 'PROCESSED', 'FAILED']).notNullable().defaultTo('UPLOADED').alter()
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('image_url')
      table.dropColumn('heatmap_url')
      table.dropColumn('overlay_url')
      table.dropColumn('anomaly_score')
      table.dropColumn('is_diseased')
      table.dropColumn('diseases_json')
      // Cannot easily revert enum default; leaving as-is
    })
  }
}
