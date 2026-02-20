class DropUsers < ActiveRecord::Migration[8.1]
  def change
    drop_table :users, if_exists: true
  end
end
