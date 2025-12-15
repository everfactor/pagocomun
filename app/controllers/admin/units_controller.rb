module Admin
  class UnitsController < BaseController
    before_action :set_unit, only: [:show, :edit, :update, :destroy]

    def index
      if params[:organization_id].present?
        @organization = find_organization(params[:organization_id])
        @units = @organization.units.order(:tower, :number)
      else
        # Show all units for super_admin, or units from user's organizations
        @units = if Current.user.role_super_admin?
          Unit.includes(:organization).order(created_at: :desc)
        else
          Unit.joins(:organization)
              .where(organizations: { id: Current.user.member_organizations.pluck(:id) })
              .order(created_at: :desc)
        end
      end
    end

    def show
      @organization = @unit.organization
    end

    def new
      if params[:organization_id].present?
        @organization = find_organization(params[:organization_id])
        @unit = @organization.units.build
      else
        @unit = Unit.new
        @organizations = Current.user.role_super_admin? ? Organization.all : Current.user.member_organizations
      end
    end

    def create
      if params[:organization_id].present?
        @organization = find_organization(params[:organization_id])
        @unit = @organization.units.build(unit_params)
      else
        @unit = Unit.new(unit_params)
        @organization = @unit.organization
      end

      if @unit.save
        respond_to do |format|
          format.html { redirect_to admin_units_path(organization_id: @unit.organization_id), notice: "Unit was successfully created." }
          format.turbo_stream
        end
      else
        @organizations = Current.user.role_super_admin? ? Organization.all : Current.user.member_organizations unless @organization
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      @organization = @unit.organization
    end

    def update
      if @unit.update(unit_params)
        respond_to do |format|
          format.html { redirect_to admin_unit_path(@unit), notice: "Unit was successfully updated." }
          format.turbo_stream
        end
      else
        @organization = @unit.organization
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      organization_id = @unit.organization_id
      @unit.destroy
      respond_to do |format|
        format.html { redirect_to admin_units_path(organization_id: organization_id), notice: "Unit was successfully deleted." }
        format.turbo_stream
      end
    end

    private

    def find_organization(org_id)
      if Current.user.role_super_admin?
        Organization.find(org_id)
      else
        Current.user.member_organizations.find(org_id)
      end
    end

    def set_unit
      @unit = if Current.user.role_super_admin?
        Unit.find(params[:id])
      else
        Unit.joins(:organization)
            .where(id: params[:id])
            .where(organizations: { id: Current.user.member_organizations.pluck(:id) })
            .first
      end
      redirect_to admin_units_path, alert: "Unit not found" unless @unit
    end

    def unit_params
      params.require(:unit).permit(:number, :tower, :proration, :organization_id)
    end
  end
end

