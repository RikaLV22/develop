require"set"

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

    users = User.where(organization_id: @current_user.organization_id)

    render json: users.select(:id, :username, :organization_id)
  end

  def show
    if @user.organization_id != @current_user.organization_id
      return render json: { error: '権限がありません' }, status: :forbidden
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
      token = encode_token({ user_id: user.id, organization_id: user.organization_id })

      render json: {
        user: {
          id: user.id,
          username: user.username,
          organization_id: user.organization_id
        },
        token: token
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(username: params[:username])

    if user&.authenticate(params[:password])
      token = encode_token({ user_id: user.id, organization_id: user.organization_id })

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
      render json: { message: "ユーザー名またはパスワードが違います" }, status: :unauthorized
    end
  end

 def update
    if @user.id != @current_user.id
      return render json: { error: '権限がありません' }, status: :forbidden
    end

    if @user.update(user_params)
      render json: {
        id: @user.id,
        username: @user.username,
        public_id: @user.public_id,
        registered_at: @user.created_at,
        organization: {
          id: @user.organization.id,
          name: @user.organization.name
        },
        avatar_url: avatar_url(@user),
        background_image_url: background_image_url(@user),
        current_streak: current_streak(@user),
        longest_streak: longest_streak(@user),
        recorded_days: recorded_days(@user)
      }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @user.id != @current_user.id
      return render json: { error: '権限がありません' }, status: :forbidden
    end

    @user.destroy
    render json: { message: 'ユーザーを削除しました' }
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:username, :password, :organization_id, :avatar, :background_image)
  end

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end

  def recorded_days(user)
  user.transactions
      .where(transaction_scope: "personal")
      .distinct
      .count(:date)
  end

  def current_streak(user)
    dates =
      user.transactions
          .where(transaction_scope: "personal")
          .distinct
          .pluck(:date)
          .map(&:to_date)

    return 0 if dates.empty?

    date_set = dates.to_set
    today = Date.current
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
          .where(transaction_scope: "personal")
          .distinct
          .pluck(:date)
          .map(&:to_date)
          .sort

    return 0 if dates.empty?

    longest = 1
    current = 1

    dates.each_cons(2) do |previous_date, current_date|
      if current_date == previous_date + 1.day
        current += 1
        longest = [longest, current].max
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
