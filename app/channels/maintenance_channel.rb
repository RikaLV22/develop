class MaintenanceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "maintenance_system"
  end

  def unsubscribed
  end
end