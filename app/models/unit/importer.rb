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

    user = nil
    if row["email_usuario"].present?
      user = find_or_create_user(row)
      return unless user # If user creation fails, we stop for this row
      ensure_membership(user)
    end

    unit = find_or_create_unit(row)
    return unless unit

    assign_user_to_unit(user, unit) if user
  end

  def row_invalid?(row)
    if row["numero_unidad"].blank?
      @errors << "Row #{$.}: Unit number (numero_unidad) is missing"
      return true
    end

    if row["torre"].blank?
      @errors << "Row #{$.}: Tower (torre) is missing"
      return true
    end

    if row["dia_pago"].blank?
      @errors << "Row #{$.}: Pay day (dia_pago) is missing"
      return true
    end

    false
  end

  def find_or_create_user(row)
    User.find_or_initialize_by(email_address: row["email_usuario"]&.strip&.downcase).tap do |u|
      u.first_name = row["nombre_usuario"]&.strip if row["nombre_usuario"].present?
      u.last_name = row["apellido_usuario"]&.strip if row["apellido_usuario"].present?

      if u.new_record?
        u.password = SecureRandom.hex(8)
        u.status = "approved"
      end

      u.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Row #{$.}: User could not be created/updated: #{e.message}"
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
    organization.units.find_or_initialize_by(number: row["numero_unidad"]&.strip, tower: row["torre"]&.strip).tap do |u|
      u.email = row["email_usuario"]&.strip&.downcase if row["email_usuario"].present?
      u.mobile_number = row["celular"]&.strip if row["celular"].present?
      u.proration = row["prorrateo"]&.to_f if row["prorrateo"].present?
      u.pay_day = row["dia_pago"]&.to_i if row["dia_pago"].present?
      u.save!
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Row #{$.}: Unit could not be created/updated: #{e.message}"
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
