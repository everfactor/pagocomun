class SessionsController < ApplicationController
  skip_before_action :set_current_user, only: [:new, :create]

  def new
    redirect_to root_path if Current.user
  end

  def create
    user = User.find_by(email_address: params[:email_address])

    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      Current.user = user
      redirect_to root_path, notice: "Welcome back, #{user.first_name}!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    Current.user = nil
    redirect_to login_path, notice: "Logged out successfully"
  end
end
