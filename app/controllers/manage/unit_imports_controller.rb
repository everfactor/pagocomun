module Manage
  class UnitImportsController < BaseController
    before_action :set_organization

    def new
      @importer = Unit::Importer.new(@organization, nil)
    end

    def create
      @importer = Unit::Importer.new(@organization, params[:file])
      if @importer.import
        redirect_to manage_units_path(organization_id: @organization.id), notice: "Unidades importadas exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      return redirect_to manage_units_path, alert: "Se requiere una organización" if params[:organization_id].blank?

      @organization = Current.user.member_organizations.find(params[:organization_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to manage_units_path, alert: "Organización no encontrada"
    end
  end
end
