class Payment < ApplicationRecord
  belongs_to :organization
  belongs_to :unit
  belongs_to :bill
  belongs_to :payment_method, optional: true
  belongs_to :payer_user, class_name: "User"

  validates :period, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :parent_buy_order, presence: true, uniqueness: true
  validates :child_buy_order, presence: true, uniqueness: true
  validates :status, presence: true

  enum :status, %w[initiated authorized failed reversed refunded].index_by(&:itself), prefix: :status
end
