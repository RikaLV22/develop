class Admin::OrganizationsController < ApplicationController
  before_action :admin_user
  before_action :set_organization, only: [:show, :destroy]

  def index
    organizations = Organization
      .includes(:organization_memberships)
      .order(created_at: :desc)

    render json: organizations.map { |organization|
      organization_json(organization)
    }
  end

  def show
    render json: organization_json(
      @organization,
      detailed: true
    )
  end

  def destroy
    if @organization.organization_memberships.exists?
      render json: {
        message: "メンバーが所属している組織は削除できません"
      }, status: :forbidden
      return
    end

    if Transaction.where(
      organization_id: @organization.id
    ).exists?
      render json: {
        message: "取引データが存在する組織は削除できません"
      }, status: :forbidden
      return
    end

    @organization.destroy!

    render json: {
      message: "組織を削除しました"
    }, status: :ok
  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_json(
    organization,
    detailed: false
  )
    member_count =
      organization.organization_memberships.count

    transaction_count =
      Transaction.where(
        organization_id: organization.id
      ).count

    data = {
      id: organization.id,
      name: organization.name,
      public_id: organization.public_id,
      created_at: organization.created_at,
      member_count: member_count,
      transaction_count: transaction_count,
      deletable:
        member_count.zero? &&
        transaction_count.zero?
    }

    if detailed
      data[:members] =
        organization.organization_memberships
          .includes(:user)
          .map do |membership|
            user = membership.user

            {
              membership_id: membership.id,
              user_id: user.id,
              username: user.username,
              public_id: user.public_id
            }
          end
    end

    data
  end
end