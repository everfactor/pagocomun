class PaymentMethod < ApplicationRecord
  belongs_to :unit_user_assignment
  has_one :user, through: :unit_user_assignment
  has_one :unit, through: :unit_user_assignment

  has_many :payments, dependent: :restrict_with_error

  validates :unit_user_assignment, presence: true
  validates :tbk_username, presence: true
  validates :tbk_token, presence: true, uniqueness: {scope: :unit_user_assignment_id}

  scope :active, -> { where(active: true) }
end
