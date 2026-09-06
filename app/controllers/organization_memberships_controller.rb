class OrganizationMembershipsController < ApplicationController
  before_action :authorized
  before_action :set_membership, only: :destroy

    def index memberships = @current_user.organization_memberships.includes(:organization) 
        render json: memberships.map { |membership| membership_json(membership) }
    end

  def create
    organization = Organization.find_by(public_id: params[:organization_public_id])

    unless organization
      return render json: { error: "指定された組織が見つかりません" }, status: :not_found
    end

    if @current_user.organizations.exists?(organization.id)
      return render json: { error: "すでに所属している組織です" }, status: :unprocessable_entity
    end

    membership = @current_user.organization_memberships.new(
      organization: organization
    )

    if membership.save
      render json: membership_json(membership), status: :created
    else
      render json: { errors: membership.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @membership.destroy
    render json: { message: "組織から脱退しました" }
  end

  private

  def set_membership
    @membership = @current_user.organization_memberships.find_by(id: params[:id])

    return if @membership

    render json: { error: "所属情報が見つかりません" }, status: :not_found
  end

  def membership_json(membership)
    {
      id: membership.id,
      organization: {
        id: membership.organization.id,
        name: membership.organization.name,
        public_id: membership.organization.public_id
      }
    }
  end
end