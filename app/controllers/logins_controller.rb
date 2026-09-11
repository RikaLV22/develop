class LoginsController < ApplicationController
  skip_before_action :authorized, only: [:create]
  skip_before_action :check_system_maintenance, only: [:create]

  def create
    user =
      User.find_by(
        username: params[:username]
      )

    if user&.authenticate(params[:password])
      if user.suspended?
        render json: {
          message: "このアカウントは利用停止中です"
        }, status: :forbidden

        return
      end

      maintenance =
        MaintenanceSetting.current

      if maintenance.block_login &&
         !user.admin?
        render json: {
          message:
            maintenance.maintenance_message.presence ||
            "現在メンテナンス中のためログインできません"
        }, status: :service_unavailable

        return
      end

      token =
        encode_token(
          user_id: user.id,
          organization_id: user.organization_id,
          token_version: user.token_version
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
        message: "ユーザー名またはパスワードが違います"
      }, status: :unauthorized
    end
  end

  private

  def encode_token(payload)
    JWT.encode(
      payload,
      Rails.application.secret_key_base,
      "HS256"
    )
  end
end
