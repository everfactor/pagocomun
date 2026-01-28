class ChargeAttempt < ApplicationRecord
  belongs_to :charge_run
  belongs_to :bill
  belongs_to :payment, optional: true

  enum :status, %w[pending success failed skipped rejected].index_by(&:itself), prefix: :status
  enum :error_type, %w[none connection gateway rejected no_payment_method other].index_by(&:itself), prefix: :error_type

  scope :retryable, -> { where(retryable: true, status: :failed) }
  scope :failed, -> { where(status: :failed) }
  scope :rejected, -> { where(status: :rejected) }
  scope :technical_errors, -> { where(retryable: true, status: :failed) }

  validates :status, presence: true
  validates :error_type, presence: true

  def mark_success!(payment_record)
    update!(
      status: :success,
      payment: payment_record,
      error_type: :none,
      retryable: false
    )
  end

  def mark_failed!(error_type, error_message, response_code = nil, retryable: false)
    update!(
      status: :failed,
      error_type: error_type,
      error_message: error_message,
      response_code: response_code,
      retryable: retryable
    )
  end

  def mark_rejected!(error_message, response_code = nil)
    update!(
      status: :rejected,
      error_type: :rejected,
      error_message: error_message,
      response_code: response_code,
      retryable: false
    )
  end

  def mark_skipped!(reason)
    update!(
      status: :skipped,
      error_type: :none,
      error_message: reason,
      retryable: false
    )
  end

  def increment_retry!
    increment!(:retry_count)
  end
end
