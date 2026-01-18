module Manage
  class BillsController < BaseController
    before_action :set_organization
    before_action :set_bill, only: [:show]

    def index
      @organizations = Current.user.member_organizations

      @bills = if @organization
        @organization.bills
      else
        Bill.joins(:unit)
          .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
          .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
          .where(organization_memberships: {user_id: Current.user.id})
          .distinct
      end

      @bills = @bills.includes(:unit, :organization).order(created_at: :desc)

      if params[:period].present?
        @bills = @bills.where(period: params[:period])
      end

      @pagy, @bills = pagy(:offset, @bills)
    end

    def show
    end

    private

    def set_organization
      if params[:organization_id].present?
        @organization = Current.user.member_organizations.find(params[:organization_id])
      end
    rescue ActiveRecord::RecordNotFound
      redirect_to manage_organizations_path, alert: "Organización no encontrada o acceso denegado."
    end

    def set_bill
      @bill = Bill.joins(:unit)
        .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
        .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
        .where(id: params[:id])
        .where(organization_memberships: {user_id: Current.user.id})
        .distinct
        .first
      redirect_to manage_bills_path, alert: "Cobro no encontrado" unless @bill
    end
  end
end
