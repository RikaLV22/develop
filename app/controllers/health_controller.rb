class HealthController < ApplicationController
  def show
    database_status = check_database
    maintenance_setting = MaintenanceSetting.current

    render json: {
      status: database_status == "ok" ? "ok" : "degraded",
      backend: "ok",
      database: database_status,
      maintenance: maintenance_setting&.system_maintenance || false,
      timestamp: Time.current.iso8601
    }
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    "ok"
  rescue StandardError => e
    Rails.logger.error(
      "Health check database error: #{e.class}: #{e.message}"
    )
    "error"
  end
end