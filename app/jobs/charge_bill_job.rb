class ChargeBillJob < ApplicationJob
  queue_as :default

  def perform(bill)
    Bill::Charger.call(bill)
  end
end
