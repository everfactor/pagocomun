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
      @organization.status = "pending" unless Current.user.role_super_admin?

      if @organization.save
        respond_to do |format|
          format.html { redirect_to admin_organizations_path, notice: "Organization was successfully created." }
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
      if @organization.update(organization_params)
        respond_to do |format|
          format.html { redirect_to admin_organization_path(@organization), notice: "Organization was successfully updated." }
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
      @organization.destroy
      respond_to do |format|
        format.html { redirect_to admin_organizations_path, notice: "Organization was successfully deleted." }
        format.turbo_stream
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
      params.require(:organization).permit(:name, :rut, :slug, :active, :org_type, :transbank_id, :address, :tbk_child_commerce_code, :status, :note)
    end
  end
end
