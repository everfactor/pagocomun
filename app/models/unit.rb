class Unit < ApplicationRecord
  belongs_to :organization
  has_many :unit_user_assignments, dependent: :destroy
  has_many :assigned_users, through: :unit_user_assignments, source: :user
  has_many :bills, dependent: :destroy
  has_many :payments, dependent: :destroy

  validates :number, presence: true
  validates :number, uniqueness: { scope: [:organization_id, :tower] }
end
