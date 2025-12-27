class HomeController < ApplicationController
  def index
    if Current.user && (Current.user.role_super_admin? || Current.user.role_org_admin?)
      redirect_to admin_dashboard_index_path
    elsif Current.user&.role_resident?
      redirect_to dashboard_index_path
    elsif Current.user
      # Fallback for other roles or future use
      redirect_to dashboard_index_path
    else
      redirect_to login_path
    end
  end
end
