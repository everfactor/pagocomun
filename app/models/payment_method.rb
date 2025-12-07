class PaymentMethod < ApplicationRecord
  belongs_to :user
  has_many :payments, dependent: :restrict_with_error

  validates :tbk_username, presence: true
  validates :tbk_token, presence: true, uniqueness: { scope: :user_id }
  validates :tbk_token, uniqueness: true

  scope :active, -> { where(active: true) }
end
