class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :organization_id,
            uniqueness: { scope: :user_id }

  validate :user_organization_limit

  after_create_commit :clear_organization_empty_since
  after_destroy_commit :mark_organization_empty_since

  private

  def user_organization_limit
    return unless user

    existing_count =
      user.organization_memberships
          .where.not(id: id)
          .count

    if existing_count >= 4
      errors.add(
        :base,
        "所属できる組織は最大4つまでです"
      )
    end
  end

  # メンバーが1人でも追加されたら、
  # 「空になった日時」を解除する
  def clear_organization_empty_since
    return unless organization

    organization.update_column(
      :empty_since_at,
      nil
    )
  end

  # メンバー削除後に0人になったら、
  # 空になった時刻を記録する
  def mark_organization_empty_since
    return unless organization
    return unless organization.persisted?

    return if organization
      .organization_memberships
      .exists?

    return if organization.empty_since_at.present?

    organization.update_column(
      :empty_since_at,
      Time.current
    )
  end
end