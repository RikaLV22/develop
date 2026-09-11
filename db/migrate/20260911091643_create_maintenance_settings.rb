class CreateMaintenanceSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_settings do |t|
      t.boolean :system_maintenance, null: false, default: false
      t.boolean :block_login, null: false, default: false
      t.string :maintenance_message
      t.boolean :calendar_enabled, null: false, default: true
      t.boolean :charts_enabled, null: false, default: true
      t.boolean :accounts_enabled, null: false, default: true
      t.boolean :organization_enabled, null: false, default: true
      t.boolean :ai_enabled, null: false, default: true
      t.timestamps
    end
  end
end