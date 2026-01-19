module Manage
  class OrganizationsController < BaseController
    before_action :set_organization, only: [:show, :edit, :update, :destroy]
    before_action :require_org_admin!, only: [:new, :create, :edit, :update, :destroy]

    private

    def require_org_admin!
      if %w[new create].include?(action_name)
        unless Current.user.can_create_organization?
          redirect_to manage_organizations_path, alert: "Acceso denegado. Solo administradores pueden realizar esta acción."
        end
      else
        unless Current.user.can_manage_organization?(@organization)
          redirect_to manage_organizations_path, alert: "Acceso denegado. Solo administradores pueden realizar esta acción."
        end
      end
    end

    public

    def index
      @pagy, @organizations = pagy(:offset, Current.user.member_organizations.order(created_at: :desc))
    end

    def show
    end

    def new
      @organization = Organization.new
    end

    def create
      @organization = Organization.new(organization_params)
      @organization.status = "approved"

      if @organization.save
        # The creator (org_admin) is automatically associated as the admin member
        @organization.organization_memberships.create!(user: Current.user, role: "org_admin", active: true)

        # Also set the organization_id on the user for the has_one :owner association
        Current.user.update!(organization: @organization) if Current.user.organization_id.nil?

        redirect_to manage_organizations_path, notice: "La organización fue creada exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @organization.update(organization_params)
        redirect_to manage_organization_path(@organization), notice: "La organización fue actualizada exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @organization.destroy
      redirect_to manage_organizations_path, notice: "La organización fue eliminada exitosamente."
    end

    private

    def set_organization
      @organization = Current.user.member_organizations.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to manage_organizations_path, alert: "Organización no encontrada o acceso denegado."
    end

    def organization_params
      params.require(:organization).permit(:name, :rut, :slug, :org_type, :address, :tbk_child_commerce_code, :note, :owner_id)
    end
  end
end
