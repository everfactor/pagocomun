class Organization < ApplicationRecord
  attr_accessor :owner_id
  has_many :users, dependent: :restrict_with_error
  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user
  has_many :units, dependent: :destroy
  has_one :admin_membership, -> { role_org_admin }, class_name: "OrganizationMembership"
  has_one :owner, through: :admin_membership, source: :user
  has_many :bills, through: :units

  enum :org_type, %w[community rental_space].index_by(&:itself), prefix: :org_type
  enum :status, %w[pending approved rejected].index_by(&:itself), prefix: :status

  validates :name, presence: true
  validates :rut, presence: true
end
