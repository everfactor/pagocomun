module Admin
  class UnitImportsController < BaseController
    before_action :set_organization

    def new
      @importer = Unit::Importer.new(@organization, nil)
    end

    def create
      @importer = Unit::Importer.new(@organization, params[:file])
      if @importer.import
        redirect_to admin_units_path(organization_id: @organization.id), notice: "Units imported successfully"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      return redirect_to admin_units_path, alert: "Organization required" if params[:organization_id].blank?

      @organization = if Current.user.role_super_admin?
        Organization.find(params[:organization_id])
      else
        Current.user.member_organizations.find(params[:organization_id])
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_units_path, alert: "Organization not found"
    end
  end
end
