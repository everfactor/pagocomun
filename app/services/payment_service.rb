class PaymentService < ApplicationService
  def initialize(bill)
    @bill = bill
    @unit = bill.unit
    @organization = @unit.organization
  end

  def call
    return failure("Bill is not set for auto-charge") unless bill.auto_charge?
    return failure("Bill is not pending") unless bill.pending?

    as_of = bill.due_date || Date.today
    assignment = find_payer_assignment(as_of)
    return failure("No payer assigned to unit") unless assignment

    payer_user = assignment.user
    payment_method = find_active_payment_method(payer_user)
    return failure("No active payment method for payer") unless payment_method

    process_payment(payer_user, payment_method)
  end

  private

  attr_reader :bill, :unit, :organization

  def find_payer_assignment(date)
    unit.unit_user_assignments.on_date(date).order(starts_on: :desc).first
  end

  def find_active_payment_method(user)
    user.payment_methods.where(active: true).first
  end

  def process_payment(payer_user, payment_method)
    parent_buy_order = "BILL-#{bill.id}"
    child_buy_order = "CHILD-#{bill.id}"

    response = authorize_payment(payment_method, parent_buy_order, child_buy_order)

    Payment.transaction do
      payment = create_payment_record(
        payer_user: payer_user,
        payment_method: payment_method,
        parent_buy_order: parent_buy_order,
        child_buy_order: child_buy_order,
        response: response
      )

      update_bill_status(response)

      if response.response_code == 0
        success(payment)
      else
        failure("Payment authorization failed", payment)
      end
    end
  end

  def authorize_payment(payment_method, parent_buy_order, child_buy_order)
    Oneclick::MallTransaction.new.authorize(
      username: payment_method.tbk_username,
      tbk_user: payment_method.tbk_token,
      buy_order: parent_buy_order,
      details: [
        {
          commerce_code: organization.tbk_child_commerce_code,
          buy_order: child_buy_order,
          amount: bill.amount
        }
      ]
    )
  end

  def create_payment_record(payer_user:, payment_method:, parent_buy_order:, child_buy_order:, response:)
    Payment.create!(
      organization: organization,
      unit: unit,
      bill: bill,
      payment_method: payment_method,
      payer_user: payer_user,
      period: bill.period,
      amount: bill.amount,
      parent_buy_order: parent_buy_order,
      child_buy_order: child_buy_order,
      tbk_auth_code: extract_auth_code(response),
      response_code: extract_response_code(response),
      status: determine_status(response),
      gateway_payload: response.as_json,
      economic_snapshot: EconomicIndicator.snapshot
    )
  end

  def extract_auth_code(response)
    response.details&.first&.authorization_code
  rescue
    nil
  end

  def extract_response_code(response)
    response.details&.first&.response_code || response.response_code
  end

  def determine_status(response)
    (response.response_code == 0) ? "authorized" : "failed"
  end

  def update_bill_status(response)
    if response.response_code == 0
      bill.update!(status: :paid)
      # TODO: send receipt
    else
      bill.update!(status: :failed)
      # TODO: retry/notify
    end
  end

  def success(payment)
    OpenStruct.new(success?: true, payment: payment, error: nil)
  end

  def failure(message, payment = nil)
    OpenStruct.new(success?: false, payment: payment, error: message)
  end
end
