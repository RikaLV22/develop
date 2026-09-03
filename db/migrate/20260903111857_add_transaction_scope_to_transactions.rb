class AddTransactionScopeToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :transaction_scope, :string, null: false, default: "organization"

    add_index :transactions, :transaction_scope
  end
end
