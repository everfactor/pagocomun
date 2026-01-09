module Manage
  class UnitImportsController < BaseController
    before_action :set_organization

    def new
      @importer = Unit::Importer.new(@organization, nil)
    end

    def create
      @importer = Unit::Importer.new(@organization, params[:file])
      if @importer.import
        redirect_to manage_organization_units_path(@organization), notice: "Unidades importadas exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      begin
        @organization = Current.user.member_organizations.find(params[:organization_id])
      rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing
        redirect_to manage_organizations_path, alert: "Organización no encontrada o acceso denegado."
      end
    end
  end
end
