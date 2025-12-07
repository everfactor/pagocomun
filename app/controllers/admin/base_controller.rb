module Admin
  class BaseController < ActionController::Base
    layout "admin"
    include SetTenant

    before_action :set_current_user, :require_admin!

    private

    def require_admin!
      redirect_to root_path, alert: "Access denied. Admin privileges required." unless admin?
    end

    def admin?
      Current.user&.role_super_admin? || Current.user&.role_org_admin?
    end

    def set_current_user
      Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
    end
  end
end
