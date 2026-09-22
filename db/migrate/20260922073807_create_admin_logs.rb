class CreateAdminLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_logs do |t|
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :target_type
      t.integer :target_id
      t.text :message, null: false
      t.string :status, null: false, default: "SUCCESS"
      t.timestamps
    end

    add_index :admin_logs, :created_at
    add_index :admin_logs, [:target_type, :target_id]
  end
end