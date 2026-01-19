class GenerateMonthlyBillsJob < ApplicationJob
  queue_as :default

  def perform
    # Ensure this runs idempotent if possible, or checks if bill exists for period
    period = Date.current.strftime("%Y-%m")
    due_date = Date.current.end_of_month

    # Fetch latest economic indicators once per job run
    latest_uf = EconomicIndicator.latest_uf
    latest_ipc = EconomicIndicator.latest_ipc

    Unit.find_each do |unit|
      next unless unit.active_assignment

      # Check if bill already exists for this unit and period
      next if unit.bills.exists?(period: period)

      # Determine amount: use rent_amount for rental_space or default 50000 for communities
      amount = if unit.organization.org_type_rental_space? && unit.rent_amount.present?
        if unit.charge_mode_uf? && latest_uf
          (unit.rent_amount * latest_uf.value).round
        else
          unit.rent_amount.to_i
        end
      else
        50000 # Fixed amount for community units for now
      end

      bill = unit.bills.create!(
        amount: amount,
        period: period,
        due_date: due_date,
        status: "pending",
        auto_charge: true
      )

      # Trigger charge if user has payment method
      # We let ChargeBillJob handle the check for payment method availability
      ChargeBillJob.perform_later(bill) if bill.persisted?
    end
  end
end
