class Organization < ApplicationRecord
  has_many :organization_memberships, dependent: :destroy
  has_many :users, through: :organization_memberships

  has_one_attached :icon_image
  has_one_attached :background_image

  validates :name, presence: true
  before_validation :generate_public_id, on: :create
  validates :public_id, presence: true, uniqueness: true

  def member_count
    organization_memberships.count
  end

  def empty?
    member_count.zero?
  end

  def auto_delete_at
    return nil unless empty_since_at

    empty_since_at + 30.days
  end

  def auto_delete_days_remaining
    return nil unless auto_delete_at

    remaining =
      (auto_delete_at.to_date - Date.current).to_i

    [remaining, 0].max
  end

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