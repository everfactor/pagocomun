class DashboardController < ApplicationController
  before_action :require_authentication!

  def index
    authorize :dashboard, :index?

    @user = current_user
    @unit = @user.active_assignment&.unit
    @bills = @unit&.bills&.order(created_at: :desc)
    @payments = @user.payments.order(created_at: :desc).limit(5)
  end
end
