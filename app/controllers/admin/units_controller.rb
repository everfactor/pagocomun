module Admin
  class UnitsController < BaseController
    before_action :set_unit, only: [:show, :edit, :update, :destroy]

    def index
      if params[:organization_id].present?
        @organization = find_organization(params[:organization_id])
        @units = @organization&.units&.order(:tower, :number) || Unit.none
      else
        # Show all units for super_admin, or units from user's organizations
        @units = Unit.joins(:organization)
          .where(organizations: {id: scoped_organizations.pluck(:id)})
          .includes(:organization)
          .order(created_at: :desc)
      end

      @pagy, @units = pagy(:offset, @units)
    end

    def show
      @organization = @unit.organization
    end

    def new
      if params[:organization_id].present?
        @organization = find_organization(params[:organization_id])
        unless @organization
          redirect_to admin_units_path, alert: "Organization not found or access denied"
          return
        end
        @unit = @organization.units.build
      else
        @unit = Unit.new
        @organizations = scoped_organizations
      end
    end

    def create
      if params[:organization_id].present?
        @organization = find_organization(params[:organization_id])
        unless @organization
          redirect_to admin_units_path, alert: "Organization not found or access denied"
          return
        end
        @unit = @organization.units.build(unit_params)
      else
        @unit = Unit.new(unit_params)
        @organization = @unit.organization

        # Validate organization_id belongs to accessible organizations
        if @organization && !scoped_organizations.include?(@organization)
          @unit.errors.add(:organization_id, "is not accessible")
          @organizations = scoped_organizations
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.turbo_stream { render :new, status: :unprocessable_entity }
          end
          return
        end
      end

      if @unit.save
        respond_to do |format|
          format.html { redirect_to admin_units_path(organization_id: @unit.organization_id), notice: "Unit was successfully created." }
          format.turbo_stream
        end
      else
        @organizations = scoped_organizations unless @organization
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
      # Validate organization_id hasn't changed to unauthorized org
      if unit_params[:organization_id].present? && unit_params[:organization_id].to_i != @unit.organization_id
        new_organization = scoped_organizations.find_by(id: unit_params[:organization_id])
        unless new_organization
          @unit.errors.add(:organization_id, "is not accessible")
          @organization = @unit.organization
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_entity }
            format.turbo_stream { render :edit, status: :unprocessable_entity }
          end
          return
        end
      end

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
      scoped_organizations.find_by(id: org_id)
    end

    def set_unit
      @unit = Unit.joins(:organization)
        .where(id: params[:id])
        .where(organizations: {id: scoped_organizations.pluck(:id)})
        .first
      unless @unit
        redirect_to admin_units_path, alert: "Unit not found or access denied"
      end
    end

    def unit_params
      params.require(:unit).permit(:number, :tower, :proration, :organization_id, :email, :mobile_number, :pay_day, :name)
    end
  end
end
