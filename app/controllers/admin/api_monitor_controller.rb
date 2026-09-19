class Admin::ApiMonitorController < ApplicationController
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
    rescue StandardError => e
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

    backend_status =
      if total_elapsed >= 1.0
        "warning"
      else
        "normal"
      end

    user_api = check_user_api
    organization_api = check_organization_api
    organization_user_api = check_organization_user_api
    personal_transaction_api = check_personal_transaction_api
    organization_transaction_api = check_organization_transaction_api
    personal_account_api = check_personal_account_api
    organization_account_api = check_organization_account_api
    bank_api = check_bank_api
    ai_api = check_ai_api

    overall_status =
      if db_status == "error" ||
         user_api[:status] == "error" ||
         organization_api[:status] == "error" ||
         organization_user_api[:status] == "error" ||
         personal_transaction_api[:status] == "error" ||
         organization_transaction_api[:status] == "error" ||
         personal_account_api[:status] == "error" ||
         organization_account_api[:status] == "error" ||
         bank_api[:status] == "error" ||
         ai_api[:status] == "error"
        "error"
      elsif backend_status == "warning" ||
            user_api[:status] == "warning" ||
            organization_api[:status] == "warning" ||
            organization_user_api[:status] == "warning" ||
            personal_transaction_api[:status] == "warning" ||
            organization_transaction_api[:status] == "warning" ||
            personal_account_api[:status] == "warning" ||
            organization_account_api[:status] == "warning" ||
            bank_api[:status] == "warning" ||
            ai_api[:status] == "warning"
        "warning"
      else
        "normal"
      end

    render json: {
      status: overall_status,

      backend: {
        status: backend_status,
        response_time_ms:
          (total_elapsed * 1000).round(2)
      },

      database: {
        status: db_status,
        response_time_ms:
          (db_elapsed * 1000).round(2),
        error: db_error
      },

      apis: [
        user_api,
        organization_api,
        organization_user_api,
        personal_transaction_api,
        organization_transaction_api,
        personal_account_api,
        organization_account_api,
        bank_api,
        ai_api
      ],

      generated_at: Time.current.iso8601
    }
  end

  private

  def check_user_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      User.limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "User API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "User API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "User API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_organization_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      Organization.limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Organization API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Organization API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Organization API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_organization_user_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      OrganizationMembership.limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Organization User API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Organization User API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Organization User API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_personal_transaction_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      Transaction.limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Personal Transaction API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Personal Transaction API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Personal Transaction API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_organization_transaction_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      Transaction.where.not(organization_id: nil).limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Organization Transaction API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Organization Transaction API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Organization Transaction API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_personal_account_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      Account.limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Personal Account API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Personal Account API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Personal Account API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_organization_account_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      Account.where.not(organization_id: nil).limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Organization Account API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Organization Account API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Organization Account API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_bank_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    begin
      Bank.limit(1).exists?

      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      {
        name: "Bank API",
        status: "normal",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: nil
      }
    rescue StandardError => e
      elapsed =
        Process.clock_gettime(
          Process::CLOCK_MONOTONIC
        ) - started_at

      Rails.logger.error(
        "Bank API health check error: #{e.class}: #{e.message}"
      )

      {
        name: "Bank API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: e.class.name,
          message: e.message
        }
      }
    end
  end

  def check_ai_api
    started_at =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    api_key =
      Rails.application.credentials.dig(
        :gemini,
        :api_key
      )

    if api_key.blank?
      return {
        name: "AI API",
        status: "error",
        response_time_ms: 0,
        error: {
          class: "GeminiAPIKeyMissing",
          message: "Gemini APIキーが設定されていません"
        }
      }
    end

    conn =
      Faraday.new(
        url: "https://generativelanguage.googleapis.com"
      ) do |faraday|
        faraday.options.timeout = 5
        faraday.options.open_timeout = 3
      end

    response =
      conn.get("/v1beta/models") do |req|
        req.headers["x-goog-api-key"] = api_key
        req.headers["Content-Type"] = "application/json"
      end

    elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - started_at

    unless response.success?
      return {
        name: "AI API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: "GeminiAPIError",
          message:
            "Gemini API returned HTTP #{response.status}",
          status_code: response.status
        }
      }
    end

    body = JSON.parse(response.body)

    models =
      body.fetch("models", []).map do |model|
        model["name"].to_s.delete_prefix("models/")
      end

    required_models = [
      "gemini-3.6-flash",
      "gemini-3.5-flash-lite"
    ]

    missing_models =
      required_models.reject do |model|
        models.include?(model)
      end

    if missing_models.any?
      return {
        name: "AI API",
        status: "error",
        response_time_ms:
          (elapsed * 1000).round(2),
        error: {
          class: "GeminiModelUnavailable",
          message:
            "必要なGeminiモデルが利用できません",
          missing_models: missing_models
        }
      }
    end

    {
      name: "AI API",
      status: "normal",
      response_time_ms:
        (elapsed * 1000).round(2),
      error: nil
    }
  rescue Faraday::TimeoutError => e
    elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - started_at

    Rails.logger.error(
      "AI API health check timeout: #{e.class}: #{e.message}"
    )

    {
      name: "AI API",
      status: "error",
      response_time_ms:
        (elapsed * 1000).round(2),
      error: {
        class: e.class.name,
        message: e.message
      }
    }
  rescue Faraday::ConnectionFailed => e
    elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - started_at

    Rails.logger.error(
      "AI API health check connection error: #{e.class}: #{e.message}"
    )

    {
      name: "AI API",
      status: "error",
      response_time_ms:
        (elapsed * 1000).round(2),
      error: {
        class: e.class.name,
        message: e.message
      }
    }
  rescue JSON::ParserError => e
    elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - started_at

    Rails.logger.error(
      "AI API health check JSON error: #{e.class}: #{e.message}"
    )

    {
      name: "AI API",
      status: "error",
      response_time_ms:
        (elapsed * 1000).round(2),
      error: {
        class: e.class.name,
        message: e.message
      }
    }
  rescue StandardError => e
    elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - started_at

    Rails.logger.error(
      "AI API health check error: #{e.class}: #{e.message}"
    )

    {
      name: "AI API",
      status: "error",
      response_time_ms:
        (elapsed * 1000).round(2),
      error: {
        class: e.class.name,
        message: e.message
      }
    }
  end
end