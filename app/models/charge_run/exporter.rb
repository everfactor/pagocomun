class ChargeRun::Exporter
  def initialize(charge_run, format: :csv)
    @charge_run = charge_run
    @format = format
  end

  def export
    method = "export_#{@format}"
    return public_send(method) if respond_to?(method, true)

    raise ArgumentError, "Unsupported format: #{@format}"
  end

  private

  def export_csv
    CSV.generate(headers: true) do |csv|
      csv << headers
      @charge_run.charge_attempts.includes(:bill, :payment, bill: [:unit, :organization]).find_each do |attempt|
        csv << row_data(attempt)
      end
    end
  end

  def export_xlsx
    require "caxlsx"
    package = Axlsx::Package.new
    workbook = package.workbook
    worksheet = workbook.add_worksheet(name: "Charge Attempts")

    worksheet.add_row(headers)

    @charge_run.charge_attempts.includes(:bill, :payment, bill: [:unit, :organization]).find_each do |attempt|
      worksheet.add_row(row_data(attempt))
    end

    package.to_stream.read
  end

  def headers
    [
      "Fecha",
      "Organización",
      "Unidad",
      "Período",
      "Monto",
      "Estado",
      "Tipo de Error",
      "Mensaje de Error",
      "Código de Respuesta",
      "Intentos",
      "Reintentable"
    ]
  end

  def row_data(attempt)
    bill = attempt.bill
    unit = bill.unit
    org = bill.organization

    [
      attempt.created_at.strftime("%Y-%m-%d %H:%M:%S"),
      org.name,
      unit.number,
      bill.period,
      bill.amount,
      attempt.status,
      attempt.error_type,
      attempt.error_message,
      attempt.response_code,
      attempt.retry_count,
      attempt.retryable ? "Sí" : "No"
    ]
  end
end
