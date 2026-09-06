class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :organization_id,
            uniqueness: { scope: :user_id }

  validate :user_organization_limit

  private

  def user_organization_limit
    return unless user

    existing_count =
      user.organization_memberships
          .where.not(id: id)
          .count

    if existing_count >= 4
      errors.add(:base, "所属できる組織は最大4つまでです")
    end
  end
end