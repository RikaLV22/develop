class Admin::MaintenanceController < ApplicationController
  before_action :admin_user

  def show
    render json: maintenance_json
  end

  def update
    maintenance = MaintenanceSetting.current

    ActiveRecord::Base.transaction do
      system_maintenance_changed =
        maintenance.system_maintenance !=
        maintenance_params[:system_maintenance]

      block_login_changed =
        maintenance.block_login !=
        maintenance_params[:block_login]

      maintenance.update!(
        maintenance_params
      )

      if system_maintenance_changed &&
         maintenance.system_maintenance
        force_logout_all_users
      elsif block_login_changed &&
            maintenance.block_login
        force_logout_all_users
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
    count = force_logout_all_users

    render json: {
      message: "一般ユーザーを強制ログアウトしました",
      count: count
    }
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