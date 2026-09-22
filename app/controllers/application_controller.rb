class ApplicationController < ActionController::API
  around_action :capture_system_error

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

  def capture_system_error
    error_logged = false

    begin
      yield
    rescue => error
      record_system_error(
        error: error,
        status_code: error_status_code(error)
      )

      error_logged = true

      raise
    ensure
      if !error_logged && response.status.to_i >= 400
        record_http_error(response.status.to_i)
      end
    end
  end

  def record_system_error(error:, status_code:)
    SystemErrorLog.create!(
      error_code: error_code_for(error, status_code),
      status_code: status_code,
      exception_class: error.class.name,
      request_method: request.request_method,
      path: request.path,
      controller_name: controller_name,
      action_name: action_name,
      message: error.message.presence || error.class.name,
      user_id: @current_user&.id,
      backtrace: Array(error.backtrace).first(20).join("\n")
    )
  rescue => log_error
    Rails.logger.error(
      "[SystemErrorLog] ログ保存失敗: #{log_error.message}"
    )
  end

  def record_http_error(status_code)
    SystemErrorLog.create!(
      error_code: "HTTP_#{status_code}",
      status_code: status_code,
      exception_class: nil,
      request_method: request.request_method,
      path: request.path,
      controller_name: controller_name,
      action_name: action_name,
      message: "HTTP #{status_code} response",
      user_id: @current_user&.id
    )
  rescue => log_error
    Rails.logger.error(
      "[SystemErrorLog] HTTPエラーログ保存失敗: #{log_error.message}"
    )
  end

  def error_status_code(error)
    case error
    when ActiveRecord::RecordNotFound
      404
    when ActionController::ParameterMissing
      400
    when ActiveRecord::RecordInvalid
      422
    when ActiveRecord::RecordNotUnique
      409
    else
      500
    end
  end

  def error_code_for(error, status_code)
    case error
    when ActiveRecord::RecordNotFound
      "RECORD_NOT_FOUND"
    when ActionController::ParameterMissing
      "PARAMETER_MISSING"
    when ActiveRecord::RecordInvalid
      "RECORD_INVALID"
    when ActiveRecord::RecordNotUnique
      "RECORD_NOT_UNIQUE"
    else
      "HTTP_#{status_code}"
    end
  end

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