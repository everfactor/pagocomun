module Manage
  class DashboardController < BaseController
    def index
      @organizations = Current.user.role_super_admin? ? Organization.all : Current.user.member_organizations
      @users = User.joins(:member_organizations).where.not(role: "resident").where(organization_memberships: {organization_id: @organizations.pluck(:id)}).distinct
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

      # Alerts
      @current_period = Time.current.strftime("%Y-%m")
      @missing_bill_uploads = @organizations.where.not(last_bill_upload_period: @current_period)

      @overdue_bills = @bills.where(status: "pending").where("due_date < ?", Date.current).includes(:unit, :organization)

      # Units without active user assignment
      @units_missing_assignment = @units.where.not(id: UnitUserAssignment.active.select(:unit_id))

      # Economic Indicators status
      @indicators = EconomicIndicator.snapshot
      @uf_sync_error = Rails.cache.read("cmf_sync_error_uf")
      @ipc_sync_error = Rails.cache.read("cmf_sync_error_ipc")
    end
  end
end
