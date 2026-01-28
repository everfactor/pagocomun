class DailyCharge::Runner < ApplicationService
  def initialize(date: Date.current)
    @date = date
  end

  def call
    charge_run = ChargeRun.create!(
      run_type: :scheduled,
      status: :pending,
      organization: nil
    )

    charge_run.start!

    process_organizations(charge_run)
    charge_run.complete!
  rescue => e
    charge_run.fail!(e.message)
    Rails.logger.error("DailyChargeJob Error: #{e.message}")
    raise
  end

  private

  attr_reader :date

  def process_organizations(charge_run)
    Organization.where(active: true, status: :approved).find_each do |organization|
      process_organization(organization, charge_run)
    end
  end

  def process_organization(organization, charge_run)
    # Find units whose pay_day matches today
    # Handle end-of-month: if pay_day is 31 and today is last day of month, also process
    last_day_of_month = date.end_of_month.day
    today_day = date.day

    units_to_charge = organization.units.where(
      "pay_day = :today_day OR (pay_day > :last_day_of_month AND :today_day = :last_day_of_month)",
      today_day: today_day,
      last_day_of_month: last_day_of_month
    )

    units_to_charge.find_each do |unit|
      unit.bills.where(status: :pending).where("due_date IS NULL OR due_date <= ?", date).find_each do |bill|
        next unless bill.auto_charge?

        ChargeAttemptJob.perform_later(charge_run, bill)
      end
    end
  end
end
