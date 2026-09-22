class DeleteExpiredOrganizationsJob < ApplicationJob
  queue_as :default

  def perform
    organizations =
      Organization
        .where.not(empty_since_at: nil)
        .where(
          "empty_since_at <= ?",
          30.days.ago
        )

    organizations.find_each do |organization|
      delete_organization(organization)
    end
  end

  private

  def delete_organization(organization)
    return unless organization.persisted?
    return if organization.organization_memberships.exists?

    organization_name = organization.name
    organization_id = organization.id

    ActiveRecord::Base.transaction do
      Transaction
        .where(
          organization_id: organization_id,
          transaction_scope: "organization"
        )
        .destroy_all

      organization.destroy!

      Rails.logger.info(
        "[OrganizationCleanup] " \
        "30日経過した空組織を削除しました: " \
        "#{organization_id} #{organization_name}"
      )
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    Rails.logger.error(
      "[OrganizationCleanup] " \
      "組織削除失敗: " \
      "#{organization.id} #{e.message}"
    )
  rescue ActiveRecord::InvalidForeignKey => e
    Rails.logger.error(
      "[OrganizationCleanup] " \
      "外部キー制約で削除失敗: " \
      "#{organization.id} #{e.message}"
    )
  end
end