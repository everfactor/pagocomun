class GenerateMonthlyBillsJob < ApplicationJob
  queue_as :default

  def perform
    # Ensure this runs idempotent if possible, or checks if bill exists for period
    period = Date.current.strftime("%Y-%m")
    due_date = Date.current.end_of_month

    Unit.find_each do |unit|
      next unless unit.active_assignment

      # Check if bill already exists for this unit and period
      next if unit.bills.exists?(period: period)

      # Fixed amount for now as requested (e.g., 50000 CLP).
      # Later we can add 'amount' to Unit or Organization config.
      amount = 50000

      bill = unit.bills.create!(
        amount: amount,
        period: period,
        due_date: due_date,
        status: "pending",
        auto_charge: true # Default to true for now to attempt charge? or depends on user pref?
      )

      # Trigger charge if user has payment method
      # We let ChargeBillJob handle the check for payment method availability
      ChargeBillJob.perform_later(bill) if bill.persisted?
    end
  end
end
