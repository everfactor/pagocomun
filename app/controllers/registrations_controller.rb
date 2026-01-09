class RegistrationsController < ApplicationController
  skip_before_action :set_current_user, only: [:new, :create]

  def new
    redirect_to root_path if Current.user
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.status = "pending" # Ensure status is pending for new signups

    if @user.save
      redirect_to login_path, notice: "Account created successfully! Your account is pending approval. You will be able to sign in once an administrator approves your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email_address,
      :password,
      :password_confirmation,
      :first_name,
      :last_name,
      :signup_note
    ).with_defaults(role: "org_admin")
  end
end
