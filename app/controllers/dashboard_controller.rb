class DashboardController < ApplicationController
  def index
    if Current.user&.role_super_admin?
      redirect_to admin_dashboard_index_path and return
    elsif Current.user&.role_org_admin? || Current.user&.role_manager?
      redirect_to manage_dashboard_index_path and return
    end

    @token = params[:token]
    @user = User.locate_signed(@token) || GlobalID::Locator.locate(params[:user_id])
    @unit = @user.active_assignment&.unit
    @bills = @unit&.bills&.order(created_at: :desc)
    @payments = @user.payments.order(created_at: :desc).limit(5)
  end
end
