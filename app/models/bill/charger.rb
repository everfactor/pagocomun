require "ostruct"

class Bill::Charger < ApplicationService
  def initialize(bill)
    @bill = bill
  end

  def call
    precheck = precheck_result
    return precheck if precheck

    # Extract required data
    organization = bill.unit.organization
    assignment = bill.unit.active_assignment
    user = assignment.user
    payment_method = assignment.payment_method

    # Mark bill as pending while processing
    bill.update(status: "pending")

    # Generate unique buy order with timestamp
    buy_order = "BILL-#{bill.id}-#{Time.now.to_i}"

    # Authorize payment with Transbank
    response = authorize_payment(payment_method:, amount: bill.amount, buy_order:)

    # Handle response and create payment record
    handle_gateway_response(
      response:,
      organization:,
      user:,
      payment_method:,
      amount: bill.amount,
      buy_order:
    )
  rescue Transbank::Shared::TransbankError => e
    gateway_error(e)
  rescue Faraday::Error, Timeout::Error, Errno::ECONNREFUSED, Errno::ETIMEDOUT => e
    connection_error(e)
  rescue => e
    unexpected_error(e)
  end

  private

  attr_reader :bill

  def precheck_result
    # Skip if bill is already paid
    return skip_result("Bill already paid") if bill.status_paid?

    # Skip if bill is in invalid state
    if bill.status == "failed" || bill.status == "processing"
      return skip_result("Bill in invalid state: #{bill.status}")
    end

    # Check for active assignment
    assignment = bill.unit.active_assignment
    unless assignment&.user
      return skip_result("No active assignment for unit")
    end

    # Check for active payment method
    payment_method = assignment.payment_method
    unless payment_method&.active?
      return skip_result("No active payment method for payer")
    end

    # All checks passed
    nil
  end

  def authorize_payment(payment_method:, amount:, buy_order:)
    TransbankClient.mall_transaction.authorize(
      payment_method.tbk_username,
      payment_method.tbk_token,
      "P-#{buy_order}",
      [
        {
          commerce_code: bill.unit.organization.tbk_child_commerce_code,
          buy_order: buy_order,
          amount: amount,
          installments_number: 1
        }
      ]
    )
  end

  def handle_gateway_response(response:, organization:, user:, payment_method:, amount:, buy_order:)
    # Extract first detail from response (Transbank returns array of details)
    detail = response["details"]&.first

    unless detail
      return result(
        success: false,
        error_type: :gateway,
        error_message: "Invalid response: missing details"
      )
    end

    response_code = detail["response_code"]

    # Response code 0 means success
    if response_code == 0
      payment = create_payment!(
        response:,
        detail:,
        organization:,
        user:,
        payment_method:,
        amount:,
        buy_order:
      )
      result(success: true, payment: payment)
    else
      # Payment rejected by bank (insufficient funds, card issues, etc.)
      bill.update(status: "failed")
      result(
        success: false,
        error_type: :rejected,
        error_message: "Payment rejected by gateway (code: #{response_code})",
        response_code: response_code
      )
    end
  end

  def create_payment!(response:, detail:, organization:, user:, payment_method:, amount:, buy_order:)
    payment = nil

    ActiveRecord::Base.transaction do
      # Create payment record with Transbank response data
      payment = Payment.create!(
        bill: bill,
        organization: organization,
        unit: bill.unit,
        payer_user: user,
        payment_method: payment_method,
        amount: amount,
        status: "authorized",
        period: bill.period,
        parent_buy_order: "P-#{buy_order}",
        child_buy_order: buy_order,
        gateway_payload: response, # Already a hash
        response_code: detail["response_code"],
        tbk_auth_code: detail["authorization_code"],
        economic_snapshot: EconomicIndicator.snapshot
      )

      # Mark bill as paid
      bill.update!(status: "paid")
    end

    payment
  end

  def gateway_error(error)
    bill.update(status: "failed")

    result(
      success: false,
      error_type: :gateway,
      error_message: "Transbank gateway error: #{error.message}",
      retryable: true
    )
  end

  def connection_error(error)
    # Keep bill as pending so it can be retried
    bill.update(status: "pending")

    result(
      success: false,
      error_type: :connection,
      error_message: "Connection error: #{error.message}",
      retryable: true
    )
  end

  def unexpected_error(error)
    bill.update(status: "failed")

    result(
      success: false,
      error_type: :other,
      error_message: "Unexpected error: #{error.message}",
      retryable: false
    )
  end

  # Helper method for skip results
  def skip_result(message)
    result(
      success: false,
      error_type: :no_payment_method,
      error_message: message,
      skipped: true
    )
  end

  # Build result object
  def result(success:, payment: nil, error_type: :none, error_message: nil, response_code: nil, retryable: false, skipped: false)
    OpenStruct.new(
      success?: success,
      payment: payment,
      error_type: error_type,
      error_message: error_message,
      response_code: response_code,
      retryable: retryable,
      skipped: skipped
    )
  end
end
