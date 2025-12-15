class RegistrationsController < ApplicationController
  skip_before_action :set_current_user, only: [:new, :create]

  def new
    redirect_to root_path if Current.user
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    @user.status = "pending" # Ensure status is pending for new signups

    # Validate role is one of the allowed signup roles
    unless %w[org_admin manager resident].include?(@user.role)
      @user.errors.add(:role, "is not a valid selection")
      render :new, status: :unprocessable_entity
      return
    end

    if @user.save
      redirect_to login_path, notice: "Account created successfully! Your account is pending approval. You will be able to sign in once an administrator approves your account."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :first_name, :last_name, :role, :signup_note)
  end
end
