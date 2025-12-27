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
    unit_number = row["unit_number"]&.strip
    tower = row["tower"]&.strip
    email = row["user_email"]&.strip&.downcase
    first_name = row["user_first_name"]&.strip
    last_name = row["user_last_name"]&.strip

    if unit_number.blank?
      @errors << "Row #{$.}: Unit number is missing"
      return
    end

    if email.blank?
      @errors << "Row #{$.}: User email is missing"
      return
    end

    # Find or Create User
    user = User.find_or_initialize_by(email_address: email)
    if user.new_record?
      user.first_name = first_name
      user.last_name = last_name
      user.password = SecureRandom.hex(8) # Temporary password
      user.status = "approved"
      # User belongs to the organization if they are created in this context?
      # Schema says users have organization_id.
      user.organization = organization

      unless user.save
        @errors << "Row #{$.}: User could not be created: #{user.errors.full_messages.join(', ')}"
        return
      end
    end

    # Find or Create Unit
    unit = organization.units.find_or_initialize_by(number: unit_number, tower: tower)
    if unit.new_record?
      unit.proration = 0
      unless unit.save
        @errors << "Row #{$.}: Unit could not be created: #{unit.errors.full_messages.join(', ')}"
        return
      end
    end

    # Assign User to Unit
    assignment = UnitUserAssignment.find_or_initialize_by(unit: unit, user: user, active: true)
    if assignment.new_record?
      assignment.starts_on = Date.current
      unless assignment.save
        @errors << "Row #{$.}: Could not assign user to unit: #{assignment.errors.full_messages.join(', ')}"
      end
    end
  end
end
