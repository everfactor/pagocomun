require "ostruct"

class Bill::Charger < ApplicationService
  def initialize(bill)
    @bill = bill
  end

  def call
    precheck = precheck_result
    return precheck if precheck

    organization = bill.unit.organization
    assignment = bill.unit.active_assignment
    user = assignment.user
    payment_method = assignment.payment_method

    bill.update(status: "pending")

    amount = bill.amount
    buy_order = "BILL-#{bill.id}-#{Time.now.to_i}"

    response = authorize_payment(payment_method:, amount:, buy_order:)
    handle_gateway_response(
      response:,
      organization:,
      user:,
      payment_method:,
      amount:,
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
    return result(success: false, error_type: :none, error_message: "Bill already paid", skipped: true) if bill.status_paid?

    if bill.status == "failed" || bill.status == "processing"
      return result(success: false, error_type: :none, error_message: "Bill in invalid state: #{bill.status}", skipped: true)
    end

    assignment = bill.unit.active_assignment
    unless assignment&.user
      return result(success: false, error_type: :no_payment_method, error_message: "No active assignment for unit", skipped: true)
    end

    payment_method = assignment.payment_method
    unless payment_method&.active?
      return result(success: false, error_type: :no_payment_method, error_message: "No active payment method for payer", skipped: true)
    end

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
    detail = response.details.first

    if detail.response_code == 0
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
      bill.update(status: "failed")
      result(
        success: false,
        error_type: :rejected,
        error_message: "Payment rejected by gateway",
        response_code: detail.response_code
      )
    end
  end

  def create_payment!(response:, detail:, organization:, user:, payment_method:, amount:, buy_order:)
    payment = nil
    ActiveRecord::Base.transaction do
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
        gateway_payload: response.as_json,
        response_code: detail.response_code,
        tbk_auth_code: detail.authorization_code,
        economic_snapshot: EconomicIndicator.snapshot
      )
      bill.update!(status: "paid")
    end
    payment
  end

  def gateway_error(error)
    bill.update(status: "failed")
    Rails.logger.error("Bill::Charger Transbank Error for Bill #{bill.id}: #{error.message}")
    result(
      success: false,
      error_type: :gateway,
      error_message: "Transbank gateway error: #{error.message}",
      retryable: true
    )
  end

  def connection_error(error)
    bill.update(status: "pending") # Keep as pending for retry
    Rails.logger.error("Bill::Charger Connection Error for Bill #{bill.id}: #{error.message}")
    # Network/connection errors are retryable
    result(
      success: false,
      error_type: :connection,
      error_message: "Connection error: #{error.message}",
      retryable: true
    )
  end

  def unexpected_error(error)
    bill.update(status: "failed")
    Rails.logger.error("Bill::Charger Error for Bill #{bill.id}: #{error.message}")
    result(
      success: false,
      error_type: :other,
      error_message: "Unexpected error: #{error.message}",
      retryable: false
    )
  end

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
