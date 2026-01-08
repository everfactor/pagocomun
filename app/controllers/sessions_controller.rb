class SessionsController < ApplicationController
  skip_before_action :set_current_user, only: [:new, :create]

  def new
    redirect_to root_path if Current.user
  end

  def create
    user = User.find_by(email_address: params[:email_address])

      if user&.authenticate(params[:password])
      unless user.status_approved?
        flash.now[:alert] = case user.status
                            when "pending"
                              "Su cuenta está pendiente de aprobación. Por favor, espere a que un administrador la apruebe."
                            when "rejected"
                              "Su cuenta ha sido rechazada. Por favor, contacte con soporte para más información."
                            else
                              "Su cuenta no está activa. Por favor, contacte con soporte."
                            end
        render :new, status: :unprocessable_entity
        return
      end

      session[:user_id] = user.id
      Current.user = user
      if user.role_super_admin?
        redirect_to admin_dashboard_index_path, notice: "¡Bienvenido de nuevo, #{user.first_name || user.email_address}!"
      elsif user.role_org_admin? || user.role_manager?
        redirect_to manage_dashboard_index_path, notice: "¡Bienvenido de nuevo, #{user.first_name || user.email_address}!"
      else
        redirect_to root_path, notice: "¡Bienvenido de nuevo, #{user.first_name || user.email_address}!"
      end
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    Rails.logger.info "Destroying session for user: #{Current.user.inspect}"
    session[:user_id] = nil
    Current.user = nil
    redirect_to login_path, notice: "Logged out successfully"
  end
end
