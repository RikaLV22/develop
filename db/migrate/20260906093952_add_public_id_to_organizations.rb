class AddPublicIdToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :public_id, :string
    add_index :organizations, :public_id, unique: true
  end
end