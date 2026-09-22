class Admin::MaintenanceController < ApplicationController
  before_action :admin_user

  def show
    render json: maintenance_json
  end

  def update
    maintenance = MaintenanceSetting.current

    logout_count = 0
    logout_reason = nil
    changed_fields = []

    ActiveRecord::Base.transaction do
      params_data = maintenance_params

      # 更新前の値を保存
      before_system_maintenance =
        maintenance.system_maintenance

      before_block_login =
        maintenance.block_login

      # どの設定が変わったか確認
      if before_system_maintenance !=
         params_data[:system_maintenance]
        changed_fields << "システムメンテナンス"
      end

      if before_block_login !=
         params_data[:block_login]
        changed_fields << "新規ログイン停止"
      end

      if maintenance.maintenance_message !=
         params_data[:maintenance_message]
        changed_fields << "メンテナンスメッセージ"
      end

      if params_data.key?(:calendar_enabled) &&
         maintenance.calendar_enabled !=
         params_data[:calendar_enabled]
        changed_fields << "カレンダー"
      end

      if params_data.key?(:charts_enabled) &&
         maintenance.charts_enabled !=
         params_data[:charts_enabled]
        changed_fields << "グラフ"
      end

      if params_data.key?(:accounts_enabled) &&
         maintenance.accounts_enabled !=
         params_data[:accounts_enabled]
        changed_fields << "口座"
      end

      if params_data.key?(:organization_enabled) &&
         maintenance.organization_enabled !=
         params_data[:organization_enabled]
        changed_fields << "組織"
      end

      if params_data.key?(:ai_enabled) &&
         maintenance.ai_enabled !=
         params_data[:ai_enabled]
        changed_fields << "AI"
      end

      if params_data.key?(:personal_balance_chart_enabled) &&
         maintenance.personal_balance_chart_enabled !=
         params_data[:personal_balance_chart_enabled]
        changed_fields << "自分の収支推移"
      end

      if params_data.key?(:personal_category_chart_enabled) &&
         maintenance.personal_category_chart_enabled !=
         params_data[:personal_category_chart_enabled]
        changed_fields << "自分の支出カテゴリ"
      end

      if params_data.key?(:organization_balance_chart_enabled) &&
         maintenance.organization_balance_chart_enabled !=
         params_data[:organization_balance_chart_enabled]
        changed_fields << "組織の収支推移"
      end

      if params_data.key?(:organization_personal_balance_chart_enabled) &&
         maintenance.organization_personal_balance_chart_enabled !=
         params_data[:organization_personal_balance_chart_enabled]
        changed_fields << "組織メンバー収支"
      end

      if params_data.key?(:organization_category_chart_enabled) &&
         maintenance.organization_category_chart_enabled !=
         params_data[:organization_category_chart_enabled]
        changed_fields << "組織の支出カテゴリ"
      end

      if params_data.key?(:organization_user_balance_chart_enabled) &&
         maintenance.organization_user_balance_chart_enabled !=
         params_data[:organization_user_balance_chart_enabled]
        changed_fields << "組織ユーザー別収支"
      end

      # メンテナンス設定を更新
      maintenance.update!(
        params_data
      )

      # システムメンテナンスON
      if before_system_maintenance !=
         maintenance.system_maintenance &&
         maintenance.system_maintenance

        logout_reason =
          "システムメンテナンスを有効化したため"

        logout_count =
          force_logout_all_users
      # ログイン停止ON
      elsif before_block_login !=
            maintenance.block_login &&
            maintenance.block_login

        logout_reason =
          "新規ログイン停止を有効化したため"

        logout_count =
          force_logout_all_users
      end

      # 設定変更ログ
      if changed_fields.any?
        create_admin_log(
          action: "UPDATE_MAINTENANCE",
          target: maintenance,
          message:
            "メンテナンス設定を更新しました（#{changed_fields.join('、')}）"
        )
      end

      # 自動強制ログアウトログ
      if logout_count > 0
        create_admin_log(
          action: "FORCE_LOGOUT_ALL",
          target_type: "User",
          target_id: nil,
          message:
            "#{logout_reason}。一般ユーザー#{logout_count}人を強制ログアウトしました"
        )
      end
    end

    broadcast_maintenance_update

    render json: {
      message: "メンテナンス設定を更新しました",
      maintenance: maintenance_json
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
  end

  def logout_all
    count = 0

    ActiveRecord::Base.transaction do
      count =
        force_logout_all_users

      create_admin_log(
        action: "FORCE_LOGOUT_ALL",
        target_type: "User",
        target_id: nil,
        message:
          "一般ユーザー#{count}人を強制ログアウトしました"
      )
    end

    render json: {
      message: "一般ユーザーを強制ログアウトしました",
      count: count
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      message: e.message
    }, status: :unprocessable_entity
  end

  private

  def maintenance_setting
    @maintenance_setting ||=
      MaintenanceSetting.current
  end

  def maintenance_params
    params
      .require(:maintenance)
      .permit(
        :system_maintenance,
        :block_login,
        :maintenance_message,
        :calendar_enabled,
        :charts_enabled,
        :accounts_enabled,
        :organization_enabled,
        :ai_enabled,
        :personal_balance_chart_enabled,
        :personal_category_chart_enabled,
        :organization_balance_chart_enabled,
        :organization_personal_balance_chart_enabled,
        :organization_category_chart_enabled,
        :organization_user_balance_chart_enabled
      )
  end

  def force_logout_all_users
    User.where(role: :user).update_all(
      "token_version = token_version + 1"
    )
  end

  def create_admin_log(
    action:,
    target: nil,
    target_type: nil,
    target_id: nil,
    message:,
    status: "SUCCESS"
  )
    AdminLog.create!(
      admin: @current_user,
      action: action,
      target_type:
        target_type ||
        target&.class&.name,
      target_id:
        target_id ||
        target&.id,
      message: message,
      status: status
    )
  end

  def broadcast_maintenance_update
    maintenance = maintenance_setting

    payload = {
      type: "maintenance_updated",
      maintenance: {
        system_maintenance:
          maintenance.system_maintenance,
        block_login:
          maintenance.block_login,
        maintenance_message:
          maintenance.maintenance_message,
        features: {
          calendar:
            maintenance.calendar_enabled,
          charts:
            maintenance.charts_enabled,
          accounts:
            maintenance.accounts_enabled,
          organization:
            maintenance.organization_enabled,
          ai:
            maintenance.ai_enabled,
          personal_balance_chart:
            maintenance.personal_balance_chart_enabled,
          personal_category_chart:
            maintenance.personal_category_chart_enabled,
          organization_balance_chart:
            maintenance.organization_balance_chart_enabled,
          organization_personal_balance_chart:
            maintenance.organization_personal_balance_chart_enabled,
          organization_category_chart:
            maintenance.organization_category_chart_enabled,
          organization_user_balance_chart:
            maintenance.organization_user_balance_chart_enabled
        },
        updated_at:
          maintenance.updated_at
      }
    }

    ActionCable.server.broadcast(
      "admin_system",
      payload
    )

    ActionCable.server.broadcast(
      "maintenance_system",
      payload
    )
  end

  def maintenance_json
    maintenance = maintenance_setting

    {
      system_maintenance:
        maintenance.system_maintenance,
      block_login:
        maintenance.block_login,
      maintenance_message:
        maintenance.maintenance_message,
      features: {
        calendar:
          maintenance.calendar_enabled,
        charts:
          maintenance.charts_enabled,
        accounts:
          maintenance.accounts_enabled,
        organization:
          maintenance.organization_enabled,
        ai:
          maintenance.ai_enabled,
        personal_balance_chart:
          maintenance.personal_balance_chart_enabled,
        personal_category_chart:
          maintenance.personal_category_chart_enabled,
        organization_balance_chart:
          maintenance.organization_balance_chart_enabled,
        organization_personal_balance_chart:
          maintenance.organization_personal_balance_chart_enabled,
        organization_category_chart:
          maintenance.organization_category_chart_enabled,
        organization_user_balance_chart:
          maintenance.organization_user_balance_chart_enabled
      },
      updated_at:
        maintenance.updated_at
    }
  end
end