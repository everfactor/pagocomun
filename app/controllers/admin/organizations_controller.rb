module Admin
  class OrganizationsController < BaseController
    before_action :set_organization, only: [:show, :edit, :update, :destroy]

    def index
      @organizations = if Current.user.role_super_admin?
        Organization.all.order(created_at: :desc)
      else
        Current.user.member_organizations.order(created_at: :desc)
      end
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
        # Associate the owner if provided (usually by super_admin)
        if @organization.owner_id.present?
          owner = User.find(@organization.owner_id)
          @organization.organization_memberships.create!(user: owner, role: "admin", active: true)
          # Also set the organization_id on the user for the has_one :owner association
          owner.update!(organization: @organization) if owner.organization_id.nil?
        elsif !Current.user.role_super_admin?
          # Automatically associate the creator if they are not a super_admin
          @organization.organization_memberships.create!(user: Current.user, role: "admin", active: true)
          Current.user.update!(organization: @organization) if Current.user.organization_id.nil?
        end

        respond_to do |format|
          format.html { redirect_to admin_organizations_path, notice: "Organization was successfully created." }
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
          format.html { redirect_to admin_organization_path(@organization), notice: "Organization was successfully updated." }
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
        format.html { redirect_to admin_organizations_path, notice: "Organization was successfully deleted." }
      end
    end

    private

    def set_organization
      @organization = if Current.user.role_super_admin?
        Organization.find(params[:id])
      else
        Current.user.member_organizations.find(params[:id])
      end
    end

    def organization_params
      params.require(:organization).permit(:name, :rut, :slug, :active, :org_type, :address, :tbk_child_commerce_code, :note, :owner_id).with_defaults(status: "approved")
    end
  end
end
