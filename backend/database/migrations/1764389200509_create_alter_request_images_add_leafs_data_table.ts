import { BaseSchema } from '@adonisjs/lucid/schema'

export default class extends BaseSchema {
  protected tableName = 'request_images'

  async up() {
    this.schema.alterTable(this.tableName, (table) => {
      // Store complete leafs array from AI response
      table.text('leafs_data').nullable()
      // Store summary data (total_leafs, diseased_leafs, healthy_leafs)
      table.text('summary_json').nullable()
    })
  }

  async down() {
    this.schema.alterTable(this.tableName, (table) => {
      table.dropColumn('leafs_data')
      table.dropColumn('summary_json')
    })
  }
}
