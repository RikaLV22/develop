class Admin::SystemController < ApplicationController
  before_action :admin_user

  def status
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    db_started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    db_status = "normal"
    db_error = nil

    begin
      ActiveRecord::Base.connection.select_value("SELECT 1")
    rescue => e
      db_status = "error"
      db_error = e.message
    end

    db_elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - db_started_at

    total_elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - started_at

    overall_status =
      if db_status == "error"
        "error"
      elsif total_elapsed >= 1.0
        "warning"
      else
        "normal"
      end

    render json: {
      status: overall_status,
      backend: {
        status: "normal",
        response_time_ms:
          (total_elapsed * 1000).round(2)
      },
      database: {
        status: db_status,
        response_time_ms:
          (db_elapsed * 1000).round(2),
        error: db_error
      },
      generated_at: Time.current.iso8601
    }
  end

  def restart
    restart_file = Rails.root.join("tmp", "restart.txt")

    FileUtils.mkdir_p(restart_file.dirname)
    FileUtils.touch(restart_file)

    render json: {
      status: "restarting",
      message: "Rails restart requested",
      generated_at: Time.current.iso8601
    }, status: :accepted
  end
end