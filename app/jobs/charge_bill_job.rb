class ChargeBillJob < ApplicationJob
  queue_as :default

  def perform(bill_id)
    bill = Bill.find(bill_id)
    result = PaymentService.call(bill)

    unless result.success?
      Rails.logger.error("Failed to charge bill #{bill_id}: #{result.error}")
      # TODO: Handle failure (retry, notify, etc.)
    end
  end
end
