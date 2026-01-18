class Unit::BillsImporter
  attr_reader :organization, :file, :errors

  def initialize(organization, file)
    @organization = organization
    @file = file
    @errors = []
  end

  def import
    return false unless valid_file?

    last_period = nil

    ActiveRecord::Base.transaction do
      CSV.foreach(file.path, headers: true) do |row|
        process_row(row)
        last_period = row["periodo"] if row["periodo"].present?
      end

      if @errors.any?
        raise ActiveRecord::Rollback
      else
        @organization.update(last_bill_upload_period: last_period) if last_period
      end
    end

    @errors.empty?
  end

  private

  def valid_file?
    if file.nil?
      @errors << "No se ha subido ningún archivo"
      return false
    end

    unless file.respond_to?(:path)
      @errors << "Formato de archivo inválido"
      return false
    end

    true
  end

  def process_row(row)
    return if row_invalid?(row)

    unit = find_unit(row)
    unless unit
      @errors << "Fila #{$.}: No se encontró la unidad #{row["depto"]} en torre #{row["edificio_torre"]}"
      return
    end

    update_unit_contact(unit, row["email_telefono"]) if row["email_telefono"].present?

    create_bill(unit, row)
  end

  def row_invalid?(row)
    if row["depto"].blank?
      @errors << "Fila #{$.}: El número de departamento (depto) es obligatorio"
      return true
    end

    if row["edificio_torre"].blank?
      @errors << "Fila #{$.}: El edificio o torre (edificio_torre) es obligatorio"
      return true
    end

    if row["monto"].blank?
      @errors << "Fila #{$.}: El monto es obligatorio"
      return true
    end

    if row["periodo"].blank?
      @errors << "Fila #{$.}: El periodo es obligatorio"
      return true
    end

    false
  end

  def find_unit(row)
    @organization.units.find_by(number: row["depto"]&.strip, tower: row["edificio_torre"]&.strip)
  end

  def update_unit_contact(unit, contact)
    if contact.include?("@")
      unit.update(email: contact.strip.downcase)
    else
      unit.update(mobile_number: contact.strip)
    end
  end

  def create_bill(unit, row)
    bill = unit.bills.find_or_initialize_by(period: row["periodo"]&.strip)
    bill.amount = row["monto"].to_i
    bill.due_date = calculate_due_date(unit, row["periodo"])
    bill.status = "pending" unless bill.status_paid?
    bill.save!
  rescue ActiveRecord::RecordInvalid => e
    @errors << "Fila #{$.}: No se pudo crear el cobro: #{e.message}"
  end

  def calculate_due_date(unit, period)
    # period format expected: "YYYY-MM"
    year, month = period.split("-").map(&:to_i)
    day = unit.pay_day || 5 # default to 5th if not set
    Date.new(year, month, day)
  rescue
    nil
  end
end
