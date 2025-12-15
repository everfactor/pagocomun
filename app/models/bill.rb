class Bill < ApplicationRecord
  belongs_to :unit
  has_one :organization, through: :unit
  has_many :payments, dependent: :restrict_with_error

  enum :status, %w[pending paid failed].index_by(&:itself), prefix: :status

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :period, presence: true
end
