class ChargeBillJob < ApplicationJob
  queue_as :default

  def perform(bill)
    Bill::Charger.new(bill).call
  end
end
