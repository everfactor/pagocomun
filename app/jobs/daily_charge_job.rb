class DailyChargeJob < ApplicationJob
  queue_as :default

  def perform
    DailyCharge::Runner.call
  end
end
