class Unit < ApplicationRecord
  belongs_to :organization
  has_many :unit_user_assignments, dependent: :destroy
  has_many :payment_methods, through: :unit_user_assignments
  has_many :assigned_users, through: :unit_user_assignments, source: :user
  has_many :bills, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :user, primary_key: :email, foreign_key: :email_address

  enum :charge_mode, %w[clp uf].index_by(&:itself), prefix: :charge_mode
  enum :ipc_adjustment, %w[monthly quarterly cuatrimestral semestral annual].index_by(&:itself), prefix: :ipc_adjustment

  validates :number, presence: true
  validates :tower, presence: true
  validates :email, presence: true, allow_nil: true
  validates :number, uniqueness: {scope: [:organization_id, :tower]}
  validates :pay_day, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 31}

  # Rental space specific validations
  with_options if: -> { organization&.org_type_rental_space? } do |rental|
    rental.validates :contract_start_on, presence: true
    rental.validates :charge_mode, presence: true
    rental.validates :ipc_adjustment, presence: true
    rental.validates :daily_interest_rate, presence: true, numericality: {greater_than_or_equal_to: 0}
    rental.validates :rent_amount, presence: true, numericality: {greater_than: 0}
    rental.validates :email, presence: true
    rental.validates :mobile_number, presence: true, format: {with: /\A\+569\d{8}\z/, message: "debe tener formato +56982672160"}
    rental.validates :name, presence: true
  end

  validate :single_unit_for_rental_space, if: -> { organization&.org_type_rental_space? }

  private

  def single_unit_for_rental_space
    return unless organization.units.where.not(id: id).exists?
    errors.add(:base, "Solo se permite una unidad para este tipo de organización")
  end

  normalizes :email, with: ->(email) { email&.strip&.downcase }

  after_save :sync_unit_user_assignment, if: :saved_change_to_email?

  has_one :active_assignment, -> {
    where(active: true)
      .where("starts_on <= ?", Date.current)
      .where("ends_on IS NULL OR ends_on >= ?", Date.current)
  }, class_name: "UnitUserAssignment"

  private

  def sync_unit_user_assignment
    return if email.blank?

    user = User.find_by(email_address: email) || User.create!(
      email_address: email,
      first_name: name,
      role: "resident",
      status: "pending",
      password: SecureRandom.hex(16)
    )

    # Check if this user is already the active assignment
    return if active_assignment&.user_id == user.id

    # Deactivate existing assignments
    unit_user_assignments.active.update_all(active: false, ends_on: Date.current)

    # Create new assignment
    unit_user_assignments.create!(
      user: user,
      starts_on: Date.current,
      active: true
    )
  end
end
