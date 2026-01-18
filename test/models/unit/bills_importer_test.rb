require "test_helper"
require "csv"

class Unit::BillsImporterTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @unit = @organization.units.create!(number: "101", tower: "A", pay_day: 5, email: "unit101@example.com")
    @file = Tempfile.new(["bills", ".csv"])
    @file.write("edificio_torre,depto,monto,periodo\n")
    @file.write("A,101,50000,2026-01\n")
    @file.rewind
  end

  teardown do
    @file.close
    @file.unlink
  end

  test "imports bills for units" do
    importer = Unit::BillsImporter.new(@organization, @file)
    assert importer.import, "Import failed with errors: #{importer.errors.join(", ")}"

    bill = @unit.bills.find_by(period: "2026-01")
    assert bill, "Bill should exist"
    assert_equal 50000, bill.amount
    assert_equal "2026-01", @organization.reload.last_bill_upload_period
  end

  test "updates unit contact info during import" do
    @file.rewind
    @file.write("edificio_torre,depto,monto,periodo,email_telefono\n")
    @file.write("A,101,50000,2026-01,newemail@example.com\n")
    @file.rewind

    importer = Unit::BillsImporter.new(@organization, @file)
    assert importer.import

    assert_equal "newemail@example.com", @unit.reload.email
  end

  test "fails when edificio_torre is missing" do
    @file.rewind
    @file.truncate(0)
    @file.write("edificio_torre,depto,monto,periodo\n")
    @file.write(",101,50000,2026-01\n")
    @file.rewind

    importer = Unit::BillsImporter.new(@organization, @file)
    refute importer.import
    assert_includes importer.errors.first, "edificio_torre) es obligatorio"
  end
end
