class User < ApplicationRecord
  belongs_to :organization

  has_secure_password

  has_many :transactions, dependent: :destroy

  has_many :accounts, dependent: :nullify

  has_many :organization_transactions,
           -> { where(transaction_scope: "organization") },
           class_name: "Transaction"

  has_many :personal_transactions,
           -> { where(transaction_scope: "personal") },
           class_name: "Transaction"
end