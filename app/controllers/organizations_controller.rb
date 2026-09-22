class OrganizationsController < ApplicationController
  before_action :authorized, except: [:index]
  before_action :set_organization, only: %i[show update destroy users]

  def index
    render json: Organization.select(
      :id,
      :name,
      :public_id
    )
  end

  def show
    transactions =
      Transaction.where(
        organization_id: @organization.id,
        transaction_scope: "organization"
      )

    total_income =
      transactions
        .where(transaction_type: "income")
        .sum(:amount)

    total_expense =
      transactions
        .where(transaction_type: "expense")
        .sum(:amount)

    balance =
      total_income - total_expense

    render json: {
      id: @organization.id,
      name: @organization.name,
      public_id: @organization.public_id,
      total_income: total_income,
      total_expense: total_expense,
      balance: balance,
      member_count:
        @organization.organization_memberships.count,
      icon_image_url:
        organization_image_url(
          @organization.icon_image
        ),
      background_image_url:
        organization_image_url(
          @organization.background_image
        )
    }
  end

  def create
    organization =
      Organization.new(
        organization_params
      )

    if organization.save
      membership =
        @current_user.organization_memberships.new(
          organization: organization
        )

      if membership.save
        render json: {
          id: organization.id,
          name: organization.name,
          public_id: organization.public_id
        }, status: :created
      else
        organization.destroy

        render json: {
          errors:
            membership.errors.full_messages
        }, status: :unprocessable_entity
      end
    else
      render json: {
        errors:
          organization.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    logger.debug(
      "【更新前】organization: #{@organization.attributes.inspect}"
    )

    logger.debug(
      "【受け取ったparams】#{organization_params.inspect}"
    )

    if @organization.update(
      organization_params
    )
      logger.debug(
        "【更新後】organization: #{@organization.attributes.inspect}"
      )

      render json: {
        id: @organization.id,
        name: @organization.name,
        public_id: @organization.public_id
      }
    else
      logger.debug(
        "【更新失敗】errors: #{@organization.errors.full_messages.inspect}"
      )

      render json: {
        errors:
          @organization.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    organization =
      @current_user.organizations.find_by(
        id: params[:id]
      )

    unless organization
      return render json: {
        error: "所属していない組織です"
      }, status: :forbidden
    end

    other_members_count =
      organization
        .organization_memberships
        .where.not(
          user_id: @current_user.id
        )
        .count

    if other_members_count > 0
      return render json: {
        error:
          "他のメンバーが所属しているため、組織を削除できません"
      }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      # この組織に紐づく組織取引をすべて削除
      Transaction
        .where(
          organization_id: organization.id,
          transaction_scope: "organization"
        )
        .destroy_all

      # 自分の所属を削除
      organization
        .organization_memberships
        .where(
          user_id: @current_user.id
        )
        .destroy_all

      # 組織を削除
      organization.destroy!
    end

    render json: {
      message: "組織と関連する取引データを削除しました"
    }, status: :ok

  rescue ActiveRecord::RecordNotDestroyed => e
    render json: {
      error: e.message
    }, status: :unprocessable_entity

  rescue ActiveRecord::InvalidForeignKey
    render json: {
      error:
        "関連データが残っているため、組織を削除できません"
    }, status: :unprocessable_entity
  end

  def users
    members =
      @organization.users.select(
        :id,
        :username,
        :public_id
      )

    render json: members
  end

  private

  def set_organization
    @organization =
      @current_user.organizations.find_by(
        id: params[:id] ||
          params[:organization_id]
      )

    return if @organization

    render json: {
      error: "所属していない組織です"
    }, status: :forbidden
  end

  def organization_params
    params
      .require(:organization)
      .permit(
        :name,
        :icon_image,
        :background_image
      )
  end

  def organization_image_url(attachment)
    return nil unless attachment.attached?

    url_for(attachment)
  end
end