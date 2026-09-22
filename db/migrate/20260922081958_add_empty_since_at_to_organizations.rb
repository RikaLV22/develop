class AddEmptySinceAtToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations,
                :empty_since_at,
                :datetime

    add_index :organizations,
              :empty_since_at
  end
end