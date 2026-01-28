class UnitUserAssignment < ApplicationRecord
  belongs_to :unit
  belongs_to :user
  has_one :payment_method, dependent: :destroy

  scope :on_date, ->(date) { where("starts_on <= ? AND (ends_on IS NULL OR ends_on >= ?)", date, date) }
  scope :active, -> { where(active: true) }

  validates :starts_on, presence: true

  after_create_commit :send_enrollment_invitation
  after_update_commit :send_enrollment_invitation, if: :saved_change_to_user_id?

  private

  def send_enrollment_invitation
    user.send_enrollment_email
  end
end
