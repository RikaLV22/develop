class ApplicationController < ActionController::API
  before_action :authorized

  def authorized
    return if logged_in_user

    Rails.logger.debug "=== AUTH FAILED ==="
    render json: { message: 'ログインしてください' }, status: :unauthorized
  end

  def logged_in_user
    header = request.headers['Authorization']
    token = header.split(' ').last if header
    decoded = decode_token(token)
    return nil unless decoded

    Rails.logger.debug "JWT decoded: #{decoded}"
    @current_user = User.find_by(id: decoded['user_id'])
  rescue => e
    Rails.logger.debug "JWT ERROR: #{e.message}"
    nil
  end

  private

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