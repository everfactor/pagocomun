class Unit < ApplicationRecord
  belongs_to :organization
  has_many :unit_user_assignments, dependent: :destroy
  has_many :assigned_users, through: :unit_user_assignments, source: :user
  has_many :bills, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :user, primary_key: :email, foreign_key: :email_address

  validates :number, presence: true
  validates :email, presence: true
  validates :number, uniqueness: { scope: [:organization_id, :tower] }

  has_one :active_assignment, -> {
    where(active: true)
    .where("starts_on <= ?", Date.current)
    .where("ends_on IS NULL OR ends_on >= ?", Date.current)
  }, class_name: "UnitUserAssignment"
end
