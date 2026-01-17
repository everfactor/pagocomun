module Admin
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy, :approve, :reject]
    before_action :require_user_creation_access!, only: [:new, :create]

    def index
      @users = if Current.user.role_super_admin?
        User.all
      else
        # Org admins see users from their organizations
        User.joins(:member_organizations)
          .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
          .distinct
      end

      @users = @users.search_by_name(params[:name]) if params[:name].present?
      @users = @users.search_by_email(params[:email]) if params[:email].present?
      @users = @users.search_by_domain(params[:domain]) if params[:domain].present?
      @users = @users.where(status: params[:status]) if params[:status].present?
      @users = @users.filter_by_organization(params[:organization_id]) if params[:organization_id].present?

      @users = @users.order(created_at: :desc)
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.status = "pending" unless Current.user.role_super_admin?

      # Validate role - only super_admin can set role
      if user_params[:role].present? && !Current.user.role_super_admin?
        @user.errors.add(:role, "cannot be set")
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
        return
      end

      # Validate organization_id if provided
      if user_params[:organization_id].present?
        organization = scoped_organizations.find_by(id: user_params[:organization_id])
        unless organization
          @user.errors.add(:organization_id, "is not accessible")
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.turbo_stream { render :new, status: :unprocessable_entity }
          end
          return
        end
      end

      if @user.save
        # Create organization membership if organization_id was provided
        if user_params[:organization_id].present?
          OrganizationMembership.create!(
            user: @user,
            organization_id: user_params[:organization_id],
            role: user_params[:role],
            active: true
          )
        end

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

      # Validate role changes - only super_admin can change role
      if update_params[:role].present? && update_params[:role] != @user.role && !Current.user.role_super_admin?
        @user.errors.add(:role, "cannot be changed")
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
        return
      end

      # Validate organization_id changes if provided
      if update_params[:organization_id].present? && update_params[:organization_id].to_i != @user.organization_id
        new_organization = scoped_organizations.find_by(id: update_params[:organization_id])
        unless new_organization
          @user.errors.add(:organization_id, "is not accessible")
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_entity }
            format.turbo_stream { render :edit, status: :unprocessable_entity }
          end
          return
        end
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

    def approve
      if @user.status_approved!
        flash.now[:notice] = "User was approved."
        respond_to do |format|
          format.html { redirect_to admin_users_path, notice: "User was approved." }
          format.turbo_stream { render :update }
        end
      else
        redirect_to admin_users_path, alert: "Failed to approve user."
      end
    end

    def reject
      if @user.status_rejected!
        flash.now[:notice] = "User was rejected."
        respond_to do |format|
          format.html { redirect_to admin_users_path, notice: "User was rejected." }
          format.turbo_stream { render :update }
        end
      else
        redirect_to admin_users_path, alert: "Failed to reject user."
      end
    end

    private

    def require_user_creation_access!
      # Admin namespace is already restricted to super_admin only via BaseController
      # This method exists for clarity and potential future use
      unless Current.user&.role_super_admin?
        redirect_to admin_users_path, alert: "Access denied. Only super admins can create users."
      end
    end

    def set_user
      @user = if Current.user.role_super_admin?
        User.find_by(id: params[:id])
      else
        User.joins(:member_organizations)
          .where(id: params[:id])
          .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
          .distinct
          .first
      end
      unless @user
        redirect_to admin_users_path, alert: "User not found or access denied"
      end
    end

    def user_params
      # Brakeman warning: :role and :status are validated in controller actions
      # Only super_admin can set these, and we validate organization_id access
      params.require(:user).permit(:email_address, :password, :password_confirmation, :first_name, :last_name, :role, :status, :note, :signup_note, :organization_id)
    end
  end
end
