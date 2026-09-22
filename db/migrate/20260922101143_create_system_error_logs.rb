class CreateSystemErrorLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :system_error_logs do |t|
      t.string :error_code, null: false
      t.integer :status_code, null: false
      t.string :exception_class

      t.string :request_method, null: false
      t.string :path, null: false

      t.string :controller_name
      t.string :action_name

      t.text :message, null: false

      t.bigint :user_id

      t.text :backtrace

      t.timestamps
    end

    add_foreign_key :system_error_logs, :users

    add_index :system_error_logs, :created_at
    add_index :system_error_logs, :status_code
    add_index :system_error_logs, :error_code
    add_index :system_error_logs, :user_id
  end
end