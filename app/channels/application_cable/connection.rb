module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_current_user
      reject_unauthorized_connection unless current_user
      reject_unauthorized_connection unless current_user.admin?
    end

    private

    def find_current_user
      token = request.params[:token]
      return nil unless token.present?

      decoded =
        JWT.decode(
          token,
          Rails.application.secret_key_base,
          true,
          algorithm: "HS256"
        )[0]

      user = User.find_by(id: decoded["user_id"])
      return nil unless user
      return nil unless decoded["token_version"].to_i == user.token_version
      return nil if user.suspended?

      user
    rescue
      nil
    end
  end
end