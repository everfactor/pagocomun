module Manage
  class BillImportsController < BaseController
    before_action :set_organization

    def new
      @importer = Unit::BillsImporter.new(@organization, nil)
    end

    def create
      @importer = Unit::BillsImporter.new(@organization, params[:file])
      if @importer.import
        redirect_to manage_bills_path(organization_id: @organization.id), notice: "Cobros importados exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      @organization = Current.user.member_organizations.find(params[:organization_id])
    rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing
      redirect_to manage_organizations_path, alert: "Organización no encontrada o acceso denegado."
    end
  end
end
