class MaintenanceStatusController < ApplicationController
  skip_before_action :authorized
  skip_before_action :check_system_maintenance

  def show
    maintenance =
      MaintenanceSetting.current

    render json: {
      calendar_enabled:
        maintenance.calendar_enabled,
      charts_enabled:
        maintenance.charts_enabled,
      accounts_enabled:
        maintenance.accounts_enabled,
      organization_enabled:
        maintenance.organization_enabled,
      ai_enabled:
        maintenance.ai_enabled,
      personal_balance_chart_enabled:
        maintenance.personal_balance_chart_enabled,
      personal_category_chart_enabled:
        maintenance.personal_category_chart_enabled,
      organization_balance_chart_enabled:
        maintenance.organization_balance_chart_enabled,
      organization_personal_balance_chart_enabled:
        maintenance.organization_personal_balance_chart_enabled,
      organization_category_chart_enabled:
        maintenance.organization_category_chart_enabled,
      organization_user_balance_chart_enabled:
        maintenance.organization_user_balance_chart_enabled
    }
  end
end