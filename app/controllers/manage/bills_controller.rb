module Manage
  class BillsController < BaseController
    before_action :set_bill, only: [:show]

    def index
      @bills = Bill.joins(:unit)
                  .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
                  .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
                  .where(organization_memberships: { user_id: Current.user.id })
                  .distinct
                  .includes(:unit, :organization)
                  .order(created_at: :desc)
    end

    def show
    end

    private

    def set_bill
      @bill = Bill.joins(:unit)
                  .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
                  .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
                  .where(id: params[:id])
                  .where(organization_memberships: { user_id: Current.user.id })
                  .distinct
                  .first
      redirect_to manage_bills_path, alert: "Cobro no encontrado" unless @bill
    end
  end
end
