class ChargeAttempt::Processor < ApplicationService
  def initialize(charge_run:, bill:, max_retries:)
    @charge_run = charge_run
    @bill = bill
    @max_retries = max_retries
  end

  def call
    attempt = ChargeAttempt.create!(charge_run:, bill:, status: :pending)
    result = Bill::Charger.call(bill)

    if result.success?
      payment = result.payment
      attempt.mark_success!(payment)
    elsif result.skipped
      attempt.mark_skipped!(result.error_message)
    elsif result.error_type == :rejected
      # Payment rejected - do not retry, notify immediately
      attempt.mark_rejected!(result.error_message, result.response_code)
      notify_payment_rejected(attempt)
    else
      # Technical error - may be retryable
      retryable = result.retryable && attempt.retry_count < max_retries
      attempt.mark_failed!(
        result.error_type,
        result.error_message,
        result.response_code,
        retryable: retryable
      )

      if retryable
        # Job will be retried automatically by ActiveJob
        attempt.increment_retry!
        raise "Retryable error: #{result.error_message}"
      else
        # Non-retryable technical error - notify admins
        notify_technical_error(attempt)
      end
    end
  rescue => e
    # If we get here, it's an unexpected error
    attempt&.mark_failed!(:other, e.message, nil, retryable: false)
    notify_technical_error(attempt) if attempt
    raise
  end

  private

  attr_reader :charge_run, :bill, :max_retries

  def notify_payment_rejected(attempt)
    organization = attempt.bill.organization
    admins = organization.organization_memberships
      .where(role: %w[org_admin org_manager], active: true)
      .includes(:user)
      .map(&:user)

    admins.each do |admin|
      ChargeNotificationMailer.payment_rejected(attempt, admin).deliver_later
    end
  end

  def notify_technical_error(attempt)
    organization = attempt.bill.organization
    admins = organization.organization_memberships
      .where(role: %w[org_admin org_manager], active: true)
      .includes(:user)
      .map(&:user)

    super_admins = User.where(role: :super_admin)

    (admins + super_admins).each do |admin|
      ChargeNotificationMailer.technical_error(attempt, admin).deliver_later
    end
  end
end
