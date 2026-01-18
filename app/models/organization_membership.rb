class OrganizationMembership < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  # You can tailor roles; including resident and viewer helps with B2B2C ACLs
  enum :role, %w[org_admin org_manager resident].index_by(&:itself), prefix: :role

  validates :organization_id, uniqueness: {scope: :user_id}
end
