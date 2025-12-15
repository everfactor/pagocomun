module Admin
  class DashboardController < BaseController
  def index
    @organizations_count = Organization.count
    @users_count = User.count
    @units_count = Unit.count
    @pending_bills_count = Bill.status_pending.count
    @paid_bills_count = Bill.status_paid.count
    @total_payments = Payment.sum(:amount)
    @recent_payments = Payment.order(created_at: :desc).limit(5)
  end
  end
end
