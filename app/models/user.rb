class User < ApplicationRecord
  belongs_to :organization, optional: true

  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships

  has_secure_password

  has_many :transactions, dependent: :destroy
  has_many :accounts, dependent: :nullify

  has_many :organization_transactions,
           -> { where(transaction_scope: "organization") },
           class_name: "Transaction"

  has_many :personal_transactions,
           -> { where(transaction_scope: "personal") },
           class_name: "Transaction"

  has_one_attached :avatar
  has_one_attached :background_image

  before_validation :generate_public_id, on: :create

  validates :public_id,
            presence: true,
            uniqueness: true

  private

  def generate_public_id
    return if public_id.present?

    loop do
      self.public_id = "USR-#{SecureRandom.alphanumeric(8).upcase}"
      break unless User.exists?(public_id: public_id)
    end
  end
end