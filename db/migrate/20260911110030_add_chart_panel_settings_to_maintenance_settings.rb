class AddChartPanelSettingsToMaintenanceSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :maintenance_settings, :personal_balance_chart_enabled, :boolean, null: false, default: true
    add_column :maintenance_settings, :personal_category_chart_enabled, :boolean, null: false, default: true
    add_column :maintenance_settings, :organization_balance_chart_enabled, :boolean, null: false, default: true
    add_column :maintenance_settings, :organization_personal_balance_chart_enabled, :boolean, null: false, default: true
    add_column :maintenance_settings, :organization_category_chart_enabled, :boolean, null: false, default: true
    add_column :maintenance_settings, :organization_user_balance_chart_enabled, :boolean, null: false, default: true
  end
end