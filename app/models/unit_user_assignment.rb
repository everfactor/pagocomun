class UnitUserAssignment < ApplicationRecord
  belongs_to :unit
  belongs_to :user
  has_one :payment_method, dependent: :destroy

  scope :on_date, ->(date) { where("starts_on <= ? AND (ends_on IS NULL OR ends_on >= ?)", date, date) }
  scope :active, -> { where(active: true) }

  validates :starts_on, presence: true
end
