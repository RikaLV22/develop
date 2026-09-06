class Organization < ApplicationRecord
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships

  has_one_attached :icon_image
  has_one_attached :background_image

  validates :name, presence: true
  before_validation :generate_public_id, on: :create
  validates :public_id, presence: true, uniqueness: true

  private

  def generate_public_id
    return if public_id.present?

    loop do
      self.public_id =
        "ORG-#{SecureRandom.alphanumeric(8).upcase}"

      break unless Organization.exists?(
        public_id: public_id
      )
    end
  end
end