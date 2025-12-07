class OrganizationMembership < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  # You can tailor roles; including resident and viewer helps with B2B2C ACLs
  enum :role, { admin: 0, manager: 1, staff: 2, viewer: 3, resident: 4 }

  validates :organization_id, uniqueness: { scope: :user_id }
end
