class OrganizationCharge::Runner < ApplicationService
  def initialize(organization:, triggered_by_user_id:, date: Date.current)
    @organization = organization
    @triggered_by_user_id = triggered_by_user_id
    @date = date
  end

  def call
    charge_run = ChargeRun.create!(
      run_type: :manual,
      status: :pending,
      organization: organization,
      triggered_by_id: triggered_by_user_id
    )

    charge_run.start!

    if organization
      process_organization(organization, charge_run)
    else
      # Process all organizations
      Organization.where(active: true, status: :approved).find_each do |org|
        process_organization(org, charge_run)
      end
    end

    charge_run.complete!
  rescue => e
    charge_run.fail!(e.message)
    org_id = organization ? organization.id : "all"
    Rails.logger.error("OrganizationChargeJob Error for Organization #{org_id}: #{e.message}")
    raise
  end

  private

  attr_reader :organization, :triggered_by_user_id, :date

  def process_organization(target_org, charge_run)
    # Find units whose pay_day matches today
    # Handle end-of-month: if pay_day is 31 and today is last day of month, also process
    last_day_of_month = date.end_of_month.day
    today_day = date.day

    units_to_charge = target_org.units.where(
      "pay_day = :today_day OR (pay_day > :last_day_of_month AND :today_day = :last_day_of_month)",
      today_day: today_day,
      last_day_of_month: last_day_of_month
    )

    units_to_charge.find_each do |unit|
      # Find pending bills for this unit that are due or past due
      unit.bills.where(status: :pending).where("due_date IS NULL OR due_date <= ?", date).find_each do |bill|
        next unless bill.auto_charge?

        ChargeAttemptJob.perform_later(charge_run, bill)
      end
    end
  end
end
