module Admin
  class DashboardController < BaseController
    def index
      @organizations_count = Organization.count
      @users_count = User.count
      @units_count = Unit.count
      @pending_bills_count = Bill.where(status: "pending").count
      @paid_bills_count = Bill.where(status: "paid").count
      @total_payments = Payment.sum(:amount)
      @recent_payments = Payment.order(created_at: :desc).limit(5)

      # Technical errors from charge attempts
      @technical_errors = ChargeAttempt.technical_errors
        .joins(:bill)
        .includes(:bill, bill: [:unit, :organization])
        .order(created_at: :desc)
        .limit(10)

      # Economic Indicators
      @indicators = EconomicIndicator.snapshot
    end
  end
end
