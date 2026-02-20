class AddNameToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :name, :string
  end
end
