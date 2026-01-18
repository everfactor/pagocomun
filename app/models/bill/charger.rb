class Bill::Charger
  attr_reader :bill

  def initialize(bill)
    @bill = bill
  end

  def call
    return false if bill.paid? || bill.status == "failed" || bill.status == "processing"

    organization = bill.unit.organization
    assignment = bill.unit.active_assignment
    return false unless assignment&.user

    user = assignment.user
    payment_method = assignment.payment_method
    return false unless payment_method&.active?

    bill.update(status: "pending")

    # Amount in CLP
    amount = bill.amount
    buy_order = "BILL-#{bill.id}-#{Time.now.to_i}"

    begin
      # The Transbank SDK MallTransaction#authorize method takes 4 positional arguments: (username, tbk_user, parent_buy_order, details)
      response = TransbankClient.mall_transaction.authorize(
        payment_method.tbk_username,
        payment_method.tbk_token,
        "P-#{buy_order}",
        [
          {
            commerce_code: organization.tbk_child_commerce_code,
            buy_order: buy_order,
            amount: amount,
            installments_number: 1
          }
        ]
      )

      detail = response.details.first

      if detail.response_code == 0
        ActiveRecord::Base.transaction do
          Payment.create!(
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
            tbk_auth_code: detail.authorization_code
          )
          bill.update!(status: "paid")
        end
        true
      else
        bill.update(status: "failed")
        false
      end
    rescue => e
      bill.update(status: "failed")
      Rails.logger.error("Bill::Charger Error for Bill #{bill.id}: #{e.message}")
      false
    end
  end
end
