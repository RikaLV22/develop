class Admin::UsersController < ApplicationController
  before_action :admin_user
  before_action :set_user, only: [:show, :suspend, :restore, :force_logout]

  def index
    users = User.order(created_at: :desc)

    render json: users.map { |user|
      user_json(user)
    }
  end

  def show
    render json: user_json(@user, detailed: true)
  end

  def suspend
    if @user.admin?
      render json: {
        message: "管理者ユーザーは停止できません"
      }, status: :forbidden
      return
    end

    @user.update!(
      suspended_at: Time.current
    )

    create_admin_log(
      action: "SUSPEND",
      target: @user,
      message: "ユーザー #{@user.username} を停止しました"
    )

    render json: {
      message: "ユーザーを停止しました",
      user: user_json(@user)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
  end

  def restore
    @user.update!(
      suspended_at: nil
    )

    create_admin_log(
      action: "RESTORE",
      target: @user,
      message: "ユーザー #{@user.username} を復元しました"
    )

    render json: {
      message: "ユーザーを復元しました",
      user: user_json(@user)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
  end

  def force_logout
    @user.update!(
      token_version: @user.token_version + 1
    )

    create_admin_log(
      action: "FORCE_LOGOUT",
      target: @user,
      message: "ユーザー #{@user.username} を強制ログアウトしました"
    )

    render json: {
      message: "ユーザーを強制ログアウトしました",
      user: user_json(@user)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def create_admin_log(action:, target:, message:, status: "SUCCESS")
    AdminLog.create!(
      admin: @current_user,
      action: action,
      target_type: target.class.name,
      target_id: target.id,
      message: message,
      status: status
    )
  end

  def user_json(user, detailed: false)
    data = {
      id: user.id,
      username: user.username,
      public_id: user.public_id,
      role: user.role,
      suspended: user.suspended?,
      suspended_at: user.suspended_at,
      created_at: user.created_at
    }

    if detailed
      data[:organizations] = user.organizations.map do |organization|
        {
          id: organization.id,
          name: organization.name,
          public_id: organization.public_id
        }
      end

      data[:organization_count] = user.organizations.count
      data[:transaction_count] = user.transactions.count
    end

    data
  end
end