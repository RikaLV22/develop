class AddBalanceToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :balance, :decimal
  end
end
