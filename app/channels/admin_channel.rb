class AdminChannel < ApplicationCable::Channel
  def subscribed
    reject unless connection.current_user&.admin?
    stream_from "admin_system"
  end
end