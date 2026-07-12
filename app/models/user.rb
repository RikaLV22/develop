class User < ApplicationRecord
  belongs_to :organization
  has_secure_password
  has_many :transactions
end
