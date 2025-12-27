class User < ApplicationRecord
  has_secure_password

  belongs_to :organization, optional: true # legacy/initial org context
  has_many :organization_memberships, dependent: :destroy
  has_many :member_organizations, through: :organization_memberships, source: :organization

  has_many :payment_methods, dependent: :destroy
  has_many :unit_user_assignments, dependent: :destroy
  has_many :assigned_units, through: :unit_user_assignments, source: :unit
  has_many :payments, foreign_key: :payer_user_id

  enum :role, %w[super_admin org_admin manager resident].index_by(&:itself), prefix: :role
  enum :status, %w[pending approved rejected].index_by(&:itself), prefix: :status

  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true, length: { minimum: 8 }, if: -> { new_record? || !password_digest.nil? }
  validate :role_allowed_for_signup, on: :create

  has_one :active_assignment, -> {
    where(active: true)
    .where("starts_on <= ?", Date.current)
    .where("ends_on IS NULL OR ends_on >= ?", Date.current)
  }, class_name: "UnitUserAssignment"

  private

  def role_allowed_for_signup
    return unless new_record?
    return if role.nil?

    unless %w[org_admin manager resident].include?(role)
      errors.add(:role, "must be one of: org_admin, manager, or resident")
    end
  end


end
