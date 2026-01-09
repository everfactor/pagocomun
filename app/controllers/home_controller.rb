class HomeController < ApplicationController
  def index
    if Current.user && Current.user.role_super_admin?
      redirect_to admin_dashboard_index_path
    elsif Current.user && (Current.user.role_org_admin? || Current.user.role_org_manager?)
      redirect_to manage_dashboard_index_path
    else
      redirect_to login_path
    end
  end
end
