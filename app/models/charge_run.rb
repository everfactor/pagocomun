class ChargeRun < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :triggered_by, class_name: "User", optional: true
  has_many :charge_attempts, dependent: :destroy

  enum :run_type, %w[scheduled manual].index_by(&:itself), prefix: :run_type
  enum :status, %w[pending running completed failed].index_by(&:itself), prefix: :status

  scope :for_organization, ->(org_id) { where(organization_id: org_id) }
  scope :by_admin, ->(user_id) {
    joins(:organization)
      .joins("INNER JOIN organization_memberships ON organization_memberships.organization_id = organizations.id")
      .where(organization_memberships: {user_id: user_id, role: %w[org_admin org_manager]})
      .distinct
  }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_errors, -> {
    joins(:charge_attempts)
      .where(charge_attempts: {status: "failed", retryable: true})
      .distinct
  }

  validates :run_type, presence: true
  validates :status, presence: true

  def start!
    update!(status: :running, started_at: Time.current)
  end

  def complete!
    update!(
      status: :completed,
      completed_at: Time.current,
      total_bills: charge_attempts.count,
      successful_charges: charge_attempts.status_success.count,
      failed_charges: charge_attempts.status_failed.count,
      skipped_charges: charge_attempts.status_skipped.count
    )
  end

  def fail!(error_message = nil)
    update!(
      status: :failed,
      completed_at: Time.current,
      error_message: error_message
    )
  end

  def summary_stats
    {
      total: charge_attempts.count,
      successful: charge_attempts.status_success.count,
      failed: charge_attempts.status_failed.count,
      skipped: charge_attempts.status_skipped.count,
      rejected: charge_attempts.status_rejected.count,
      technical_errors: charge_attempts.where(retryable: true, status: :failed).count
    }
  end
end
