class Organization < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user
  has_many :units, dependent: :destroy

  enum :org_type, %w[community rental_space].index_by(&:itself), prefix: :org_type
  enum :status, %w[pending approved rejected].index_by(&:itself), prefix: :status

  validates :name, presence: true
  validates :rut, presence: true
  validates :transbank_id, presence: true, uniqueness: true
  validates :tbk_child_commerce_code, presence: true, if: -> { org_type_community? }
end
