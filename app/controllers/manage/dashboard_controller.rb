module Manage
  class DashboardController < BaseController
    def index
      @organizations = Current.user.role_super_admin? ? Organization.all : Current.user.member_organizations
      @users = User.joins(:member_organizations).where(organization_memberships: { organization_id: @organizations.pluck(:id) }).distinct
      @units = Unit.where(organization_id: @organizations.pluck(:id))
      @bills = Bill.where(unit_id: @units.pluck(:id))
      @payments = Payment.where(organization_id: @organizations.pluck(:id))

      @organizations_count = @organizations.count
      @users_count = @users.count
      @units_count = @units.count
      @pending_bills_count = @bills.where(status: "pending").count
      @paid_bills_count = @bills.where(status: "paid").count
      @total_payments = @payments.sum(:amount)
      @recent_payments = @payments.order(created_at: :desc).limit(5)
    end
  end
end
