class LoginsController < ApplicationController
  skip_before_action :authorized, only: [:create]

  def create
    user = User.find_by(username: params[:username])

    if user&.authenticate(params[:password])
      token = encode_token(
        user_id: user.id,
        organization_id: user.organization_id
      )

      Rails.logger.debug "=== LOGIN SUCCESS ==="
      Rails.logger.debug "user_id: #{user.id}"
      Rails.logger.debug "organization_id: #{user.organization_id}"

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

  private

  def encode_token(payload)
    JWT.encode(payload, Rails.application.secret_key_base, 'HS256')
  end
end
