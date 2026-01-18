class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_current_user

  private

  def set_current_user
    if params[:token].present?
      user = GlobalID::Locator.locate_signed(params[:token], for: "enrollment")
      Current.user = user if user
    end
    Current.user ||= session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def require_authentication!
    return if Current.user
    redirect_to login_path, alert: "Please log in"
  end
end
