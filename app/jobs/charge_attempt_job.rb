class ChargeAttemptJob < ApplicationJob
  queue_as :default

  MAX_RETRIES = 3

  retry_on Faraday::Error, Timeout::Error, wait: :exponentially_longer, attempts: MAX_RETRIES
  retry_on Transbank::Shared::TransbankError, wait: :exponentially_longer, attempts: MAX_RETRIES

  def perform(charge_run, bill)
    ChargeAttempt::Processor.call(charge_run:, bill:, max_retries: MAX_RETRIES)
  end
end
