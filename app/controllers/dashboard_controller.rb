class DashboardController < ApplicationController
  def index
    if Current.user&.role_super_admin?
      redirect_to admin_dashboard_index_path and return
    elsif Current.user&.role_org_admin? || Current.user&.role_org_manager?
      redirect_to manage_dashboard_index_path and return
    end

    @token = params[:token]
    @user = User.locate_signed(@token) || GlobalID::Locator.locate(params[:user_id])

    @unit = if params[:unit_id]
      GlobalID::Locator.locate(params[:unit_id])
    else
      @user.active_assignment&.unit
    end

    # Ensure the user is actually assigned to this unit
    if @unit && !@user.assigned_units.include?(@unit)
      @unit = @user.active_assignment&.unit
    end

    @assignment = @user.unit_user_assignments.active.find_by(unit: @unit) if @unit
    @active_assignments = @user.unit_user_assignments.active.includes(unit: :organization)
    @bills = @unit&.bills&.order(created_at: :desc)
    @payments = @user.payments.order(created_at: :desc).limit(5)
  end
end
