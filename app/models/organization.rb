class Organization < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user
  has_many :communities, dependent: :destroy

  enum :org_type, { community: 0, rental_space: 1 }

  validates :name, presence: true
  validates :rut, presence: true
  validates :transbank_id, presence: true, uniqueness: true
end
