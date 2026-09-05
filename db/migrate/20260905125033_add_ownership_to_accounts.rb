class AddOwnershipToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_reference :accounts,
                  :user,
                  foreign_key: true

    add_reference :accounts,
                  :organization,
                  foreign_key: true

    add_column :accounts,
               :account_scope,
               :string

    add_index :accounts,
              :account_scope
  end
ends