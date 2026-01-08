module Manage
  class OrganizationsController < BaseController
    before_action :set_organization, only: [:show, :edit, :update, :destroy]
    before_action :require_org_admin!, only: [:new, :create]

    private

    def require_org_admin!
      redirect_to manage_organizations_path, alert: "Solo los administradores de organizaciones pueden crear nuevas organizaciones." unless Current.user.role_org_admin?
    end

    public

    def index
      @organizations = Current.user.member_organizations.order(created_at: :desc)
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
        @organization.organization_memberships.create!(user: Current.user, role: "admin", active: true)

        # Also set the organization_id on the user for the has_one :owner association
        Current.user.update!(organization: @organization) if Current.user.organization_id.nil?


        respond_to do |format|
          format.html { redirect_to manage_organizations_path, notice: "La organización fue creada exitosamente." }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      if @organization.update(organization_params)
        respond_to do |format|
          format.html { redirect_to manage_organization_path(@organization), notice: "La organización fue actualizada exitosamente." }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @organization.destroy
      respond_to do |format|
        format.html { redirect_to manage_organizations_path, notice: "La organización fue eliminada exitosamente." }
      end
    end

    private

    def set_organization
      @organization = Current.user.member_organizations.find(params[:id])
    end

    def organization_params
      params.require(:organization).permit(:name, :rut, :slug, :org_type, :address, :tbk_child_commerce_code, :note, :owner_id)
    end
  end
end
