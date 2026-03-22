class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :bank, null: false, foreign_key: true
      t.string :account_number
      t.string :decimal
      
      t.timestamps
    end
  end
end
