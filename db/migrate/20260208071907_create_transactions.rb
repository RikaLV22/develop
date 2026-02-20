class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :transaction_type
      t.string :category
      t.integer :amount
      t.date :date
      t.string :payment_method
      t.string :card_number

      t.timestamps
    end
  end
end
