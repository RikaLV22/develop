class UsersController < ApplicationController
  skip_before_action :authorized, only: [:create, :login]
  before_action :set_user, only: %i[show update destroy]

  def me
    render json: @current_user
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
        organization_id: @user.organization_id
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
    params.require(:user).permit(:username, :password, :organization_id)
  end

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end
end
