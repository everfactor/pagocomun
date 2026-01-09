module Manage
  class BaseController < ActionController::Base
    layout "manage"
    include SetTenant

    before_action :set_current_user, :require_manage_access!

    private

    def require_manage_access!
      redirect_to root_path, alert: "Access denied." unless manage_access?
    end

    def manage_access?
      Current.user&.role_org_admin? || Current.user&.role_org_manager? || Current.user&.role_super_admin?
    end

    def set_current_user
      Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
    end
  end
end
