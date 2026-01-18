require "test_helper"
require "csv"

class Unit::ImporterTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @file = Tempfile.new(["units", ".csv"])
    @file.write("numero_unidad,torre,dia_pago,email_usuario,nombre_usuario,apellido_usuario\n")
    @file.write("101,A,5,resident@example.com,John,Doe\n")
    @file.write("102,B,5,newuser@example.com,Jane,Smith\n")
    @file.rewind
  end

  teardown do
    @file.close
    @file.unlink
  end

  test "imports units and users" do
    # Clean up any existing users and units from previous test runs
    User.where(email_address: ["resident@example.com", "newuser@example.com"]).destroy_all
    @organization.units.where(number: ["101", "102"]).destroy_all

    importer = Unit::Importer.new(@organization, @file)
    assert importer.import, "Import failed with errors: #{importer.errors.join(", ")}"

    assert_equal 2, @organization.units.where(number: ["101", "102"]).count

    user1 = User.find_by(email_address: "resident@example.com")
    assert user1, "User1 should exist"
    assert_equal "John", user1.first_name, "User1 first_name should be John"

    user2 = User.find_by(email_address: "newuser@example.com")
    assert user2, "User2 should exist"
    assert_equal "Jane", user2.first_name, "User2 first_name should be Jane"

    assert UnitUserAssignment.exists?(unit: @organization.units.find_by(number: "101"), user: user1)
    assert UnitUserAssignment.exists?(unit: @organization.units.find_by(number: "102"), user: user2)
  end

  test "fails when tower is missing" do
    @file.rewind
    @file.truncate(0)
    @file.write("numero_unidad,torre,email_usuario\n")
    @file.write("103,,resident3@example.com\n")
    @file.rewind

    importer = Unit::Importer.new(@organization, @file)
    refute importer.import
    assert_includes importer.errors.first, "Tower (torre) is missing"
  end

  test "fails when pay_day is missing" do
    @file.rewind
    @file.truncate(0)
    @file.write("numero_unidad,torre,dia_pago,email_usuario\n")
    @file.write("104,A,,resident4@example.com\n")
    @file.rewind

    importer = Unit::Importer.new(@organization, @file)
    refute importer.import
    assert_includes importer.errors.first, "Pay day (dia_pago) is missing"
  end
end
