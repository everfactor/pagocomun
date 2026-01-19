require "test_helper"

class UnitTest < ActiveSupport::TestCase
  def setup
    @community_org = organizations(:one) # type: community
    @rental_org = organizations(:rental) # type: rental_space
  end

  test "rental space unit requires additional fields" do
    unit = Unit.new(organization: @rental_org, number: "101", tower: "A")
    assert_not unit.valid?
    assert_includes unit.errors[:contract_start_on], "no puede estar en blanco"
    assert_includes unit.errors[:rent_amount], "no puede estar en blanco"
    assert_includes unit.errors[:mobile_number], "no puede estar en blanco"
  end

  test "rental space unit validates mobile_number format" do
    org = Organization.create!(name: "Unique Rental Org", rut: "2-2", org_type: "rental_space")
    unit = Unit.new(
      organization: org,
      number: "101",
      tower: "A",
      contract_start_on: Date.current,
      charge_mode: "clp",
      ipc_adjustment: "annual",
      rent_amount: 500000,
      daily_interest_rate: 0,
      pay_day: 5,
      email: "tenant@example.com",
      name: "Tenant Name",
      mobile_number: "12345678"
    )
    assert_not unit.valid?
    assert_includes unit.errors[:mobile_number], "debe tener formato +56982672160"

    unit.mobile_number = "+56982672160"
    assert unit.valid?, "Unit should be valid but has errors: #{unit.errors.full_messages.join(', ')}"
  end

  test "only one unit allowed for rental space organization" do
    # First unit already exists in fixtures for org :two? Let's check.
    # Fixtures are loaded automatically.
    existing_unit = units(:one) # assuming one belongs to @rental_org in fixtures
    # Let's ensure organizations(:two) has one unit already if we want to test this.
    # Better to create manually.
    org = Organization.create!(name: "Rental Org", rut: "1-1", org_type: "rental_space")
    Unit.create!(
      organization: org,
      number: "1",
      tower: "A",
      contract_start_on: Date.current,
      charge_mode: "clp",
      ipc_adjustment: "annual",
      rent_amount: 100,
      daily_interest_rate: 0,
      pay_day: 1,
      email: "1@test.com",
      name: "Test",
      mobile_number: "+56911111111"
    )

    duplicate_unit = Unit.new(
      organization: org,
      number: "2",
      tower: "A",
      contract_start_on: Date.current,
      charge_mode: "clp",
      ipc_adjustment: "annual",
      rent_amount: 100,
      daily_interest_rate: 0,
      pay_day: 1,
      email: "2@test.com",
      name: "Test 2",
      mobile_number: "+56922222222"
    )

    assert_not duplicate_unit.valid?
    assert_includes duplicate_unit.errors[:base], "Solo se permite una unidad para este tipo de organización"
  end
end
