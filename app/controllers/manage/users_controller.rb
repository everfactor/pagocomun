module Manage
  class UsersController < BaseController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

    def index
      @users = User.joins(:member_organizations)
                   .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
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
      @user.status = "pending"

      if @user.save
        # If an organization_id was provided, link them
        if params[:user][:organization_id].present?
           OrganizationMembership.create!(
             user: @user,
             organization_id: params[:user][:organization_id],
             role: "member", # Default for new users created by org admins
             active: true
           )
        end

        respond_to do |format|
          format.html { redirect_to manage_users_path, notice: "El usuario fue creado exitosamente." }
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
      params_to_update = user_params
      if params_to_update[:password].blank?
        params_to_update.delete(:password)
        params_to_update.delete(:password_confirmation)
      end

      if @user.update(params_to_update)
        respond_to do |format|
          format.html { redirect_to manage_user_path(@user), notice: "El usuario fue actualizado exitosamente." }
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
        format.html { redirect_to manage_users_path, notice: "El usuario fue eliminado exitosamente." }
        format.turbo_stream
      end
    end

    private

    def set_user
      @user = User.joins(:member_organizations)
                  .where(id: params[:id])
                  .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
                  .distinct
                  .first
      redirect_to manage_users_path, alert: "Usuario no encontrado" unless @user
    end

    def user_params
      params.require(:user).permit(:email_address, :password, :password_confirmation, :first_name, :last_name, :role, :status, :note, :organization_id)
    end
  end
end
