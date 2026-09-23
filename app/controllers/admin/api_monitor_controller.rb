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

    user_api =
      check_user_api

    organization_api =
      check_organization_api

    organization_user_api =
      check_organization_user_api

    personal_transaction_api =
      check_personal_transaction_api

    organization_transaction_api =
      check_organization_transaction_api

    personal_account_api =
      check_personal_account_api

    organization_account_api =
      check_organization_account_api

    bank_api =
      check_bank_api

    ai_api =
      check_ai_api

    # 9つのAPI監視結果をまとめる
    api_results = [
      user_api,
      organization_api,
      organization_user_api,
      personal_transaction_api,
      organization_transaction_api,
      personal_account_api,
      organization_account_api,
      bank_api,
      ai_api
    ]

    # APIごとのメンテナンス設定を取得
    maintenance_settings =
      ApiMaintenanceSetting
        .where(
          api_name: api_results.map { |api| api[:name] }
        )
        .index_by(&:api_name)

    # 各APIに enabled を追加
    api_results.each do |api|
      setting =
        maintenance_settings[api[:name]]

      api[:enabled] =
        setting.nil? ? true : setting.enabled
    end

    # システム全体の状態を判定
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

      # ここが重要
      # 配列の中に api_results を入れず、
      # apis キーそのものに api_results を設定する
      apis: api_results,

      generated_at:
        Time.current.iso8601
    }
  end

  # API個別メンテナンス設定更新
  def update_maintenance
    api_name =
      params[:api_name]

    enabled =
      params[:enabled]

    allowed_api_names = [
      "User API",
      "Organization API",
      "Organization User API",
      "Personal Transaction API",
      "Organization Transaction API",
      "Personal Account API",
      "Organization Account API",
      "Bank API",
      "AI API"
    ]

    unless allowed_api_names.include?(api_name)
      render json: {
        message: "不正なAPI名です"
      }, status: :unprocessable_entity

      return
    end

    setting =
      ApiMaintenanceSetting.find_or_initialize_by(
        api_name: api_name
      )

    setting.enabled =
      ActiveModel::Type::Boolean.new.cast(
        enabled
      )

    setting.save!

    AdminLog.create!(
      admin: @current_user,
      action: "UPDATE_API_MAINTENANCE",
      target_type: "ApiMaintenanceSetting",
      target_id: setting.id,
      message:
        "APIメンテナンス設定を変更しました: " \
        "#{api_name} / enabled=#{setting.enabled}",
      status: "SUCCESS"
    )

    render json: {
      message:
        "APIメンテナンス設定を更新しました",

      api_name:
        setting.api_name,

      enabled:
        setting.enabled,

      updated_at:
        setting.updated_at
    }

  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
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
        "User API health check error: " \
        "#{e.class}: #{e.message}"
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
        "Organization API health check error: " \
        "#{e.class}: #{e.message}"
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
        "Organization User API health check error: " \
        "#{e.class}: #{e.message}"
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
        "Personal Transaction API health check error: " \
        "#{e.class}: #{e.message}"
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
      Transaction
        .where.not(
          organization_id: nil
        )
        .limit(1)
        .exists?

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
        "Organization Transaction API health check error: " \
        "#{e.class}: #{e.message}"
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
        "Personal Account API health check error: " \
        "#{e.class}: #{e.message}"
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
      Account
        .where.not(
          organization_id: nil
        )
        .limit(1)
        .exists?

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
        "Organization Account API health check error: " \
        "#{e.class}: #{e.message}"
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
        "Bank API health check error: " \
        "#{e.class}: #{e.message}"
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
          message:
            "Gemini APIキーが設定されていません"
        }
      }
    end

    conn =
      Faraday.new(
        url:
          "https://generativelanguage.googleapis.com"
      ) do |faraday|
        faraday.options.timeout = 5
        faraday.options.open_timeout = 3
      end

    response =
      conn.get("/v1beta/models") do |req|
        req.headers["x-goog-api-key"] =
          api_key

        req.headers["Content-Type"] =
          "application/json"
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
          status_code:
            response.status
        }
      }
    end

    body =
      JSON.parse(
        response.body
      )

    models =
      body.fetch(
        "models",
        []
      ).map do |model|

        model["name"]
          .to_s
          .delete_prefix("models/")
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
          class:
            "GeminiModelUnavailable",
          message:
            "必要なGeminiモデルが利用できません",
          missing_models:
            missing_models
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
      "AI API health check timeout: " \
      "#{e.class}: #{e.message}"
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
      "AI API health check connection error: " \
      "#{e.class}: #{e.message}"
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
      "AI API health check JSON error: " \
      "#{e.class}: #{e.message}"
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
      "AI API health check error: " \
      "#{e.class}: #{e.message}"
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