class CreateApiMaintenanceSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :api_maintenance_settings do |t|
      t.string :api_name, null: false
      t.boolean :enabled, null: false, default: true
      t.text :maintenance_message

      t.timestamps
    end

    add_index :api_maintenance_settings,
              :api_name,
              unique: true
  end
end