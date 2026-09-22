require "set"

class UsersController < ApplicationController
  skip_before_action :authorized, only: [:create, :login]
  before_action :set_user, only: %i[show update destroy]

  def me
    user = @current_user

    render json: {
      id: user.id,
      username: user.username,
      public_id: user.public_id,
      registered_at: user.created_at,
      organizations: user.organizations.map do |organization|
        {
          id: organization.id,
          name: organization.name,
          public_id: organization.public_id
        }
      end,
      avatar_url: avatar_url(user),
      background_image_url: background_image_url(user),
      current_streak: current_streak(user),
      longest_streak: longest_streak(user),
      recorded_days: recorded_days(user)
    }
  end

  def index
    Rails.logger.debug "=== USERS INDEX ==="
    Rails.logger.debug "current_user: #{@current_user.username}"
    Rails.logger.debug "organization_id: #{@current_user.organization_id}"
    Rails.logger.debug "==================="

    users =
      User.where(
        organization_id: @current_user.organization_id
      )

    render json:
      users.select(
        :id,
        :username,
        :organization_id
      )
  end

  def show
    if @user.organization_id != @current_user.organization_id
      return render json: {
        error: "権限がありません"
      }, status: :forbidden
    end

    render json: {
      id: @user.id,
      username: @user.username,
      organization_id: @user.organization_id
    }
  end

  def create
    Rails.logger.debug "=== USER CREATE PARAMS ==="
    Rails.logger.debug "username: #{params[:user][:username]}"
    Rails.logger.debug "password: #{params[:user][:password]}"
    Rails.logger.debug "organization_id: #{params[:user][:organization_id]}"
    Rails.logger.debug "=========================="

    user = User.new(user_params)

    if user.save
      token =
        encode_token(
          {
            user_id: user.id,
            organization_id: user.organization_id
          }
        )

      render json: {
        user: {
          id: user.id,
          username: user.username,
          organization_id: user.organization_id
        },
        token: token
      }, status: :created
    else
      render json: {
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def login
    user =
      User.find_by(
        username: params[:username]
      )

    if user&.authenticate(params[:password])
      token =
        encode_token(
          {
            user_id: user.id,
            organization_id: user.organization_id
          }
        )

      render json: {
        message: "ログイン成功",
        token: token,
        user: {
          id: user.id,
          username: user.username,
          organization_id: user.organization_id
        }
      }, status: :ok
    else
      render json: {
        message:
          "ユーザー名またはパスワードが違います"
      }, status: :unauthorized
    end
  end

  # =========================
  # プロフィール更新
  # =========================

  def update
    if @user.id != @current_user.id
      return render json: {
        error: "権限がありません"
      }, status: :forbidden
    end

    update_params =
      profile_update_params

    current_password =
      update_params.delete(:current_password)

    new_password =
      update_params[:password]

    username =
      update_params[:username]

    # ---------------------------------
    # ユーザー名 or パスワード変更時
    # 現在のパスワードを必須にする
    # ---------------------------------

    sensitive_change =
      username.present? ||
      new_password.present?

    if sensitive_change
      unless current_password.present?
        return render json: {
          error:
            "ユーザー名またはパスワードを変更するには現在のパスワードが必要です"
        }, status: :unprocessable_entity
      end

      unless @user.authenticate(current_password)
        return render json: {
          error:
            "現在のパスワードが正しくありません"
        }, status: :unprocessable_entity
      end
    end

    # パスワード変更する場合
    if new_password.present?
      password_confirmation =
        update_params.delete(
          :password_confirmation
        )

      @user.password =
        new_password

      @user.password_confirmation =
        password_confirmation
    else
      update_params.delete(
        :password
      )

      update_params.delete(
        :password_confirmation
      )
    end

    # その他のプロフィール情報
    @user.assign_attributes(
      update_params
    )

    if @user.save
      render_profile(@user)
    else
      render json: {
        errors:
          @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # =========================
  # アカウント削除
  # =========================

  def destroy
    if @user.id != @current_user.id
      return render json: {
        error: "権限がありません"
      }, status: :forbidden
    end

    delete_params =
      delete_account_params

    current_password =
      delete_params[:current_password]

    delete_confirmation =
      delete_params[:delete_confirmation]

    # ---------------------------------
    # 現在のパスワード確認
    # ---------------------------------

    unless current_password.present?
      return render json: {
        error:
          "アカウント削除には現在のパスワードが必要です"
      }, status: :unprocessable_entity
    end

    unless @user.authenticate(current_password)
      return render json: {
        error:
          "現在のパスワードが正しくありません"
      }, status: :unprocessable_entity
    end

    # ---------------------------------
    # 削除確認文字列
    # ---------------------------------

    unless delete_confirmation == "削除"
      return render json: {
        error:
          "削除確認文字列が正しくありません"
      }, status: :unprocessable_entity
    end

    begin
      @user.destroy!

      render json: {
        message: "ユーザーを削除しました"
      }, status: :ok

    rescue ActiveRecord::RecordNotDestroyed => e
      render json: {
        error: "ユーザーを削除できませんでした",
        details: e.message
      }, status: :unprocessable_entity

    rescue ActiveRecord::InvalidForeignKey => e
      render json: {
        error:
          "関連するデータが残っているため削除できませんでした",
        details: e.message
      }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user =
      User.find(
        params[:id]
      )
  end

  # ---------------------------------
  # 新規ユーザー作成用
  # ---------------------------------

  def user_params
    params
      .require(:user)
      .permit(
        :username,
        :password,
        :organization_id,
        :avatar,
        :background_image
      )
  end

  # ---------------------------------
  # プロフィール更新用
  # organization_id は絶対に許可しない
  # ---------------------------------

  def profile_update_params
    params
      .require(:user)
      .permit(
        :username,
        :password,
        :password_confirmation,
        :current_password,
        :avatar,
        :background_image
      )
  end

  # ---------------------------------
  # アカウント削除用
  # ---------------------------------

  def delete_account_params
    params
      .require(:user)
      .permit(
        :current_password,
        :delete_confirmation
      )
  end

  def encode_token(payload)
    JWT.encode(
      payload,
      Rails.application.secret_key_base,
      "HS256"
    )
  end

  def render_profile(user)
    render json: {
      id: user.id,
      username: user.username,
      public_id: user.public_id,
      registered_at: user.created_at,

      organization:
        if user.organization
          {
            id: user.organization.id,
            name: user.organization.name
          }
        else
          nil
        end,

      avatar_url:
        avatar_url(user),

      background_image_url:
        background_image_url(user),

      current_streak:
        current_streak(user),

      longest_streak:
        longest_streak(user),

      recorded_days:
        recorded_days(user)
    }
  end

  def recorded_days(user)
    user.transactions
        .where(
          transaction_scope: "personal"
        )
        .distinct
        .count(:date)
  end

  def current_streak(user)
    dates =
      user.transactions
          .where(
            transaction_scope: "personal"
          )
          .distinct
          .pluck(:date)
          .map(&:to_date)

    return 0 if dates.empty?

    date_set =
      dates.to_set

    today =
      Date.current

    streak = 0
    date = today

    while date_set.include?(date)
      streak += 1
      date -= 1.day
    end

    streak
  end

  def longest_streak(user)
    dates =
      user.transactions
          .where(
            transaction_scope: "personal"
          )
          .distinct
          .pluck(:date)
          .map(&:to_date)
          .sort

    return 0 if dates.empty?

    longest = 1
    current = 1

    dates.each_cons(2) do |previous_date, current_date|
      if current_date ==
         previous_date + 1.day

        current += 1

        longest =
          [longest, current].max
      else
        current = 1
      end
    end

    longest
  end

  def avatar_url(user)
    return nil unless user.avatar.attached?

    url_for(user.avatar)
  end

  def background_image_url(user)
    return nil unless user.background_image.attached?

    url_for(user.background_image)
  end
end