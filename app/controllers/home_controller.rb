class HomeController < ApplicationController
  def index
    if Current.user && (Current.user.base_super_admin? || Current.user.base_org_admin?)
      redirect_to admin_dashboard_index_path
    elsif Current.user
      # Regular user - could redirect to a user dashboard in the future
      redirect_to admin_dashboard_index_path
    else
      redirect_to login_path
    end
  end
end
