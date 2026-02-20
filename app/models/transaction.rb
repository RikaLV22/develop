class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :transaction_type, presence: true
  validates :category, presence: true
  validates :amount, presence: true
  validates :date, presence: true
end