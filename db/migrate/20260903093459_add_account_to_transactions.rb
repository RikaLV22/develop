class AddAccountToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :account, foreign_key: true
  end
end
