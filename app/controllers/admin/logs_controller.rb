class Admin::LogsController < ApplicationController
  before_action :logged_in_user
  before_action :require_admin

  def index
    logs =
      AdminLog
        .includes(:admin)
        .order(created_at: :desc)
        .limit(100)

    render json: logs.map { |log| serialize_log(log) }
  end

  private

  def require_admin
    unless @current_user&.admin?
      render json: {
        error: "管理者権限が必要です"
      }, status: :forbidden
    end
  end

  def serialize_log(log)
    {
      id: log.id,
      time: log.created_at.in_time_zone("Asia/Tokyo").strftime("%Y-%m-%d %H:%M:%S"),
      type: log.action.to_s.upcase,
      message: log.message,
      status: log.status.to_s.upcase
    }
  end
end