class DropOrganizations < ActiveRecord::Migration[8.1]
  def change
    drop_table :organizations, if_exists: true
  end
end
