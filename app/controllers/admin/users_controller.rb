module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @users = if Current.user.role_super_admin?
        User.all.order(created_at: :desc)
      else
        # Org admins see users from their organizations
        User.joins(:member_organizations)
            .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
            .distinct
            .order(created_at: :desc)
      end
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.status = "pending" unless Current.user.role_super_admin?

      if @user.save
        respond_to do |format|
          format.html { redirect_to admin_users_path, notice: "User was successfully created." }
          format.turbo_stream
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      # Only update password if provided
      update_params = user_params
      if update_params[:password].blank?
        update_params.delete(:password)
        update_params.delete(:password_confirmation)
      end

      if @user.update(update_params)
        respond_to do |format|
          format.html { redirect_to admin_user_path(@user), notice: "User was successfully updated." }
          format.turbo_stream
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @user.destroy
      respond_to do |format|
        format.html { redirect_to admin_users_path, notice: "User was successfully deleted." }
        format.turbo_stream
      end
    end

    private

    def set_user
      @user = if Current.user.role_super_admin?
        User.find(params[:id])
      else
        User.joins(:member_organizations)
            .where(id: params[:id])
            .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
            .distinct
            .first
      end
      redirect_to admin_users_path, alert: "User not found" unless @user
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation, :first_name, :last_name, :role, :status, :note, :signup_note, :organization_id)
    end
  end
end
