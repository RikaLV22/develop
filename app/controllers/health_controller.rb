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

  def user
    user_api = check_user_api

    if user_api[:status] == "ok"
      render json: user_api, status: :ok
    else
      render json: user_api, status: :service_unavailable
    end
  end

  def organization
    organization_api = check_organization_api

    if organization_api[:status] == "ok"
      render json: organization_api, status: :ok
    else
      render json: organization_api, status: :service_unavailable
    end
  end

  def organization_users
    organization_user_api = check_organization_user_api

    if organization_user_api[:status] == "ok"
      render json: organization_user_api, status: :ok
    else
      render json: organization_user_api, status: :service_unavailable
    end
  end

  def personal_transactions
    personal_transaction_api = check_personal_transaction_api

    if personal_transaction_api[:status] == "ok"
      render json: personal_transaction_api, status: :ok
    else
      render json: personal_transaction_api, status: :service_unavailable
    end
  end

  def organization_transactions
    organization_transaction_api = check_organization_transaction_api

    if organization_transaction_api[:status] == "ok"
      render json: organization_transaction_api, status: :ok
    else
      render json: organization_transaction_api, status: :service_unavailable
    end
  end

  def personal_accounts
    personal_account_api = check_personal_account_api

    if personal_account_api[:status] == "ok"
      render json: personal_account_api, status: :ok
    else
      render json: personal_account_api, status: :service_unavailable
    end
  end

  def organization_accounts
    organization_account_api = check_organization_account_api

    if organization_account_api[:status] == "ok"
      render json: organization_account_api, status: :ok
    else
      render json: organization_account_api, status: :service_unavailable
    end
  end

  def banks
    bank_api = check_bank_api

    if bank_api[:status] == "ok"
      render json: bank_api, status: :ok
    else
      render json: bank_api, status: :service_unavailable
    end
  end

  def ai
    ai_api = check_ai_api

    if ai_api[:status] == "ok"
      render json: ai_api, status: :ok
    else
      render json: ai_api, status: :service_unavailable
    end
  end

  def ai_status
    setting =
      ApiMaintenanceSetting.find_by(
        api_name: "AI API"
      )

    enabled =
      setting.nil? ? true : setting.enabled?

    render json: {
      name: "AI API",
      enabled: enabled,
      status: enabled ? "online" : "offline",
      maintenance: !enabled,
      maintenance_message:
        setting&.maintenance_message,
      updated_at:
        setting&.updated_at
    }, status: :ok
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
        status: "ok",
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
        "Health check User API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Organization API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Organization User API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Personal Transaction API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Organization Transaction API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Personal Account API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Organization Account API error: #{e.class}: #{e.message}"
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
        status: "ok",
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
        "Health check Bank API error: #{e.class}: #{e.message}"
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
      status: "ok",
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
      "Health check AI API timeout: #{e.class}: #{e.message}"
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
      "Health check AI API connection error: #{e.class}: #{e.message}"
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
      "Health check AI API JSON error: #{e.class}: #{e.message}"
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
      "Health check AI API error: #{e.class}: #{e.message}"
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