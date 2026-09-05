class Account < ApplicationRecord
  belongs_to :bank

  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  has_many :transactions,
           dependent: :nullify

  validates :account_scope,
            inclusion: {
              in: %w[personal organization]
            }
end