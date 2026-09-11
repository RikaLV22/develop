class ApplicationController < ActionController::API
  before_action :authorized
  before_action :check_system_maintenance

  def authorized
    return render_unauthorized unless logged_in_user
    return render_suspended if current_user&.suspended?
  end

  def logged_in_user
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    decoded = decode_token(token)
    return nil unless decoded

    Rails.logger.debug "JWT decoded: #{decoded}"

    @current_user = User.find_by(id: decoded['user_id'])
    return nil unless @current_user

    jwt_token_version = decoded['token_version']
    return nil unless jwt_token_version.to_i == @current_user.token_version

    @current_user
  rescue => e
    Rails.logger.debug "JWT ERROR: #{e.message}"
    nil
  end

  def current_user
    @current_user
  end

  def admin_user
    return current_user if current_user&.admin?

    render json: {
      message: '管理者権限が必要です'
    }, status: :forbidden
  end

  private

  def check_system_maintenance
    return unless MaintenanceSetting.current.system_maintenance
    return if current_user&.admin?

    render json: {
      message:
        MaintenanceSetting.current.maintenance_message.presence ||
        "現在メンテナンス中です"
    }, status: :service_unavailable
  end

  def render_unauthorized
    Rails.logger.debug "=== AUTH FAILED ==="

    render json: {
      message: 'ログインしてください'
    }, status: :unauthorized
  end

  def render_suspended
    Rails.logger.debug "=== USER SUSPENDED ==="

    render json: {
      message: 'このアカウントは利用停止中です'
    }, status: :forbidden
  end

  def decode_token(token)
    decoded = JWT.decode(
      token,
      Rails.application.secret_key_base,
      true,
      algorithm: 'HS256'
    )

    decoded[0]
  rescue
    nil
  end
end