class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :account, optional: true

  after_create :update_balance

  def update_balance
    return unless payment_method == "引き落とし"
    return unless account

    if transaction_type == "income"
      account.increment!(:balance, amount)
    else
      account.decremant!(:balance, amount)
    end
  end
  validates :transaction_type, presence: true
  validates :category, presence: true
  validates :amount, presence: true
  validates :date, presence: true
end