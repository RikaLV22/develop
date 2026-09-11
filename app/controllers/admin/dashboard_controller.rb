class Admin::DashboardController < ApplicationController
  before_action :admin_user

  def show
    today = Date.current

    render json: {
      users: {
        total: User.count,
        today: User.where(created_at: today.beginning_of_day..today.end_of_day).count
      },
      organizations: {
        total: Organization.count,
        today: Organization.where(created_at: today.beginning_of_day..today.end_of_day).count
      },
      transactions: {
        total: Transaction.count,
        today: Transaction.where(created_at: today.beginning_of_day..today.end_of_day).count
      },
      system: {
        status: 'normal'
      },
      generated_at: Time.current.iso8601
    }
  end
end