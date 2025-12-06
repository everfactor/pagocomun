class Bill < ApplicationRecord
  belongs_to :unit
  has_one :community, through: :unit
  has_one :organization, through: :community
  has_many :payments, dependent: :restrict_with_error

  enum :status, { pending: 0, paid: 1, failed: 2 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :period, presence: true
end
