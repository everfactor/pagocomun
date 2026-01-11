class User < ApplicationRecord
  include Permissions

  has_secure_password

  belongs_to :organization, optional: true # legacy/initial org context
  has_many :organization_memberships, dependent: :destroy
  has_many :member_organizations, through: :organization_memberships, source: :organization

  has_many :payment_methods, dependent: :destroy
  has_many :unit_user_assignments, dependent: :destroy
  has_many :assigned_units, through: :unit_user_assignments, source: :unit
  has_many :payments, foreign_key: :payer_user_id
  belongs_to :unit, primary_key: :email, foreign_key: :email_address, optional: true

  enum :role, %w[super_admin org_admin org_manager resident].index_by(&:itself), prefix: :role
  enum :status, %w[pending approved rejected].index_by(&:itself), prefix: :status

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true, length: {minimum: 8}, if: -> { new_record? || !password_digest.nil? }
  validate :role_allowed_for_signup, on: :create

  after_create_commit :send_enrollment_email, if: :role_resident?

  def enrollment_token
    to_sgid(expires_in: 30.days, for: "enrollment").to_s
  end

  has_one :active_assignment, -> {
    where(active: true)
      .where("starts_on <= ?", Date.current)
      .where("ends_on IS NULL OR ends_on >= ?", Date.current)
  }, class_name: "UnitUserAssignment"

  def self.locate_signed(token)
    GlobalID::Locator.locate_signed(token, for: "enrollment")
  end

  def signed_token
    to_sgid(expires_in: 30.days, for: "enrollment").to_s
  end

  # Allow skipping signup role validation for admin-created users
  def skip_signup_role_validation!
    @skip_signup_role_validation = true
  end

  private

  def send_enrollment_email
    ResidentMailer.with(user: self).enrollment_email.deliver_later
  end

  def role_allowed_for_signup
    return unless new_record?
    return if role.nil?
    # Skip validation if role is being set by an admin (super_admin can set any role)
    # This validation only applies to user signups, not admin-created users
    return if @skip_signup_role_validation

    unless %w[org_admin org_manager resident].include?(role)
      errors.add(:role, "must be one of: org_admin, org_manager, or resident")
    end
  end
end
