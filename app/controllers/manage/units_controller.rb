module Manage
  class UnitsController < BaseController
    before_action :set_organization
    before_action :set_unit, only: [:show, :edit, :update, :destroy]

    def index
      @pagy, @units = pagy(:offset, @organization.units.order(:tower, :number))
    end

    def show
    end

    def new
      @unit = @organization.units.build
    end

    def create
      @unit = @organization.units.build(unit_params)

      if @unit.save
        redirect_to manage_organization_units_path(@organization), notice: "La unidad fue creada exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @unit.update(unit_params)
        redirect_to manage_organization_unit_path(@organization, @unit), notice: "La unidad fue actualizada exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @unit.destroy
      redirect_to manage_organization_units_path(@organization), notice: "La unidad fue eliminada exitosamente."
    end

    private

    def set_organization
      @organization = Current.user.member_organizations.find(params[:organization_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to manage_organizations_path, alert: "Organización no encontrada o acceso denegado."
    end

    def set_unit
      @unit = @organization.units.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to manage_organization_units_path(@organization), alert: "Unidad no encontrada."
    end

    def unit_params
      params.require(:unit).permit(:number, :tower, :proration, :email, :mobile_number, :pay_day, :name, :contract_start_on, :charge_mode, :rent_amount, :ipc_adjustment, :daily_interest_rate)
    end
  end
end
