module Admin
  class DashboardController < BaseController
    def index
      @organizations_count = Organization.count
      @users_count = User.count
      @communities_count = Community.count
      @units_count = Unit.count
      @pending_bills_count = Bill.pending.count
      @paid_bills_count = Bill.paid.count
      @total_payments = Payment.sum(:amount)
      @recent_payments = Payment.order(created_at: :desc).limit(5)
    end
  end
end
