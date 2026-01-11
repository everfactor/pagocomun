module Manage
  class UsersController < BaseController
    before_action :require_org_admin_access!
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @users = User.joins(:member_organizations)
                   .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
                   .where.not(role: :resident)
                   .distinct
                   .order(created_at: :desc)
    end

    def show
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      @user.status = "approved" # Admins creating users approve them immediately
      # Skip signup role validation for admin-created users
      @user.skip_signup_role_validation!

      # Validate role - org_admins can only create org_manager and resident roles
      if user_params[:role].present?
        allowed_roles = %w[org_manager resident]
        unless allowed_roles.include?(user_params[:role])
          @user.errors.add(:role, "no es válido para creación")
          render :new, status: :unprocessable_entity
          return
        end
      end

      # Validate organization_id belongs to accessible organizations
      if user_params[:organization_id].present?
        organization = Current.user.member_organizations.find_by(id: user_params[:organization_id])
        unless organization
          @user.errors.add(:organization_id, "no es accesible")
          render :new, status: :unprocessable_entity
          return
        end
      end

      if @user.save
        # If an organization_id was provided (e.g. from index link), link them
        organization_id = user_params[:organization_id]
        if organization_id.present?
          OrganizationMembership.create!(user: @user, organization_id:, role: user_params[:role], active: true)
        end

        redirect_to manage_users_path, notice: "El usuario fue creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      params_to_update = user_params
      if params_to_update[:password].blank?
        params_to_update.delete(:password)
        params_to_update.delete(:password_confirmation)
      end

      if @user.update(params_to_update)
        redirect_to manage_user_path(@user), notice: "El usuario fue actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to manage_users_path, notice: "El usuario fue eliminado exitosamente."
    end

    private

    def require_org_admin_access!
      unless Current.user.role_org_admin? || Current.user.role_super_admin?
        redirect_to manage_dashboard_index_path, alert: "Acceso denegado. Solo administradores pueden gestionar usuarios."
      end
    end

    def set_user
      @user = User.joins(:member_organizations)
                  .where(id: params[:id])
                  .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
                  .distinct
                  .first
      redirect_to manage_users_path, alert: "Usuario no encontrado" unless @user
    end

    def user_params
      # Brakeman warning: :role and :status are validated in controller actions
      # Only org_admin can create users, and organization_id is validated to belong to user's orgs
      params.require(:user).permit(:email_address, :password, :password_confirmation, :first_name, :last_name, :status, :note, :organization_id, :role)
    end
  end
end
