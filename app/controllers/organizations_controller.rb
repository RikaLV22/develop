class OrganizationsController < ApplicationController
  before_action :authorized, except: [:index, :show, :create]
  before_action :set_organization, only: %i[show update destroy users]  # users を追加

  def index
    render json: Organization.all
  end

  def show
    render json: @organization
  end

  def create
    organization = Organization.new(organization_params)
    if organization.save
      render json: organization, status: :created  
    else
      render json: { errors: organization.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    logger.debug "【更新前】organization: #{@organization.attributes.inspect}"
    logger.debug "【受け取ったparams】#{organization_params.inspect}"

    if @organization.update(organization_params)
      logger.debug "【更新後】organization: #{@organization.attributes.inspect}"
      render json: @organization
    else
      logger.debug "【更新失敗】errors: #{@organization.errors.full_messages.inspect}"
      render json: { errors: @organization.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @organization.destroy
    render json: { message: "組織を削除しました" }
  end

  def users
    members = @organization.users.select(:id, :username) 
    render json: members
  end

  private

  def set_organization
    @organization = Organization.find(params[:id] || params[:organization_id])  
  rescue ActiveRecord::RecordNotFound
    render json: { error: "組織が見つかりません" }, status: :not_found
  end

  def organization_params
    params.require(:organization).permit(:name)   
  end
end