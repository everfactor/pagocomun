module Admin
  class BillsController < BaseController
    before_action :set_bill, only: [:show]

    def index
      @bills = if Current.user.role_super_admin?
        Bill.includes(:unit, :organization).order(created_at: :desc)
      else
        Bill.joins(:unit)
            .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
            .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
            .where(organization_memberships: { user_id: Current.user.id, organization_id: scoped_organizations.pluck(:id) })
            .distinct
            .includes(:unit, :organization)
            .order(created_at: :desc)
      end
    end

    def show
    end

    private

    def set_bill
      @bill = if Current.user.role_super_admin?
        Bill.find_by(id: params[:id])
      else
        Bill.joins(:unit)
            .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
            .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
            .where(id: params[:id])
            .where(organization_memberships: { user_id: Current.user.id, organization_id: scoped_organizations.pluck(:id) })
            .distinct
            .first
      end
      unless @bill
        redirect_to admin_bills_path, alert: "Bill not found or access denied"
      end
    end
  end
end

