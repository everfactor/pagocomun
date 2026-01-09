class DashboardPolicy < ApplicationPolicy
  # Residents can access the main dashboard
  def index?
    # Ensure user is logged in (handled by controller usually)
    # But explicitly: any resident, org_manager, or admin can view their respective dashboard logic
    # Here we are focusing on the Resident Dashboard
    user.present?
  end

  # Only admins can access admin dashboard - kept here or in Admin::DashboardPolicy?
  # Since Admin::BaseController handles admin auth via `require_admin!`,
  # we might not strictly need Pundit for Admin yet, but good to have.
end
