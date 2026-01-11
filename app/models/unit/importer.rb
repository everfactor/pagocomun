class Unit::Importer
  attr_reader :organization, :file, :errors

  def initialize(organization, file)
    @organization = organization
    @file = file
    @errors = []
  end

  def import
    return false unless valid_file?

    ActiveRecord::Base.transaction do
      CSV.foreach(file.path, headers: true) do |row|
        process_row(row)
      end

      if @errors.any?
        raise ActiveRecord::Rollback
      end
    end

    @errors.empty?
  end

  private

  def valid_file?
    if file.nil?
      @errors << "No file uploaded"
      return false
    end

    unless file.respond_to?(:path)
      @errors << "Invalid file format"
      return false
    end

    true
  end

  def process_row(row)
    return if row_invalid?(row)

    user = find_or_create_user(row)
    return unless user

    ensure_membership(user)

    unit = find_or_create_unit(row)
    return unless unit

    assign_user_to_unit(user, unit)
  end

  private

  def row_invalid?(row)
    if row["unit_number"].blank?
      @errors << "Row #{$.}: Unit number is missing"
      return true
    end

    if row["user_email"].blank?
      @errors << "Row #{$.}: User email is missing"
      return true
    end

    false
  end

  def find_or_create_user(row)
    User.find_or_initialize_by(email_address: row["user_email"]).tap do |u|
      if u.new_record?
        u.first_name = row["user_first_name"]&.strip
        u.last_name = row["user_last_name"]&.strip
        u.password = SecureRandom.hex(8)
        u.status = "approved"
        # Skip signup role validation - importer creates users programmatically
        u.skip_signup_role_validation!
        u.save!
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Row #{$.}: User could not be created: #{e.message}"
    nil
  end

  def ensure_membership(user)
    OrganizationMembership.find_or_initialize_by(user: user, organization: organization).tap do |m|
      m.role = :resident if m.new_record?
      m.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Row #{$.}: Membership could not be ensured: #{e.message}"
  end

  def find_or_create_unit(row)
    organization.units.find_or_initialize_by(number: row["unit_number"]&.strip, tower: row["tower"]&.strip).tap do |u|
      u.email = row["user_email"] || "#{row["unit_number"]}@example.com"
      u.mobile_number = row["mobile_number"]&.strip
      u.proration = row["proration"]&.to_f || 1.0
      u.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Row #{$.}: Unit could not be created: #{e.message}"
    nil
  end

  def assign_user_to_unit(user, unit)
    UnitUserAssignment.find_or_initialize_by(unit: unit, user: user, active: true).tap do |a|
      if a.new_record?
        a.starts_on = Date.current
        a.save!
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Row #{$.}: Could not assign user to unit: #{e.message}"
  end
end
