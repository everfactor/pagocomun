require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "valid organization" do
    org = Organization.new(
      name: "Test Org",
      rut: "33333330-9",
      tbk_child_commerce_code: "597012345699",
      org_type: "community",
      status: "approved"
    )
    assert org.valid?
  end

  test "rut is required" do
    org = Organization.new(name: "Test Org", tbk_child_commerce_code: "597012345678")
    assert_not org.valid?
    assert_includes org.errors[:rut], "no puede estar en blanco"
  end

  test "accepts rut without dots" do
    org = organizations(:one)
    org.rut = "33333330-9"
    assert org.valid?
  end

  test "normalizes rut to uppercase K" do
    org = organizations(:one)
    org.rut = "22222229-k"
    org.save!
    assert_equal "22222229-K", org.rut
  end

  test "rejects rut with dots" do
    org = organizations(:one)
    org.rut = "11.111.111-1"
    assert_not org.valid?
    assert_includes org.errors[:rut], "debe tener formato válido (ej: 76123456-7)"
  end

  test "rejects rut with invalid format" do
    org = organizations(:one)
    org.rut = "invalid"
    assert_not org.valid?
    assert_includes org.errors[:rut], "debe tener formato válido (ej: 76123456-7)"
  end

  test "rejects rut without dash" do
    org = organizations(:one)
    org.rut = "123456"
    assert_not org.valid?
    assert_includes org.errors[:rut], "debe tener formato válido (ej: 76123456-7)"
  end

  test "rejects rut with invalid check digit" do
    org = organizations(:one)
    org.rut = "11111111-2"
    assert_not org.valid?
    assert_includes org.errors[:rut], "tiene un dígito verificador inválido"
  end

  test "accepts rut with check digit K" do
    org = organizations(:one)
    org.rut = "22222229-K"
    assert org.valid?
  end

  test "accepts rut with lowercase k" do
    org = organizations(:one)
    org.rut = "22222229-k"
    assert org.valid?
  end

  test "validates uniqueness of rut" do
    existing = organizations(:one)
    org = Organization.new(
      name: "Another Org",
      rut: existing.rut,
      tbk_child_commerce_code: "597099999999",
      org_type: "community"
    )
    assert_not org.valid?
    assert_includes org.errors[:rut], "ya ha sido tomado"
  end

  test "accepts short rut with 7 digits" do
    org = organizations(:one)
    org.rut = "1111111-4"
    assert org.valid?
  end

  test "accepts rut with check digit 0" do
    org = organizations(:one)
    org.rut = "76123456-0"
    assert org.valid?
  end

  test "rejects rut with too few digits" do
    org = organizations(:one)
    org.rut = "111111-1"
    assert_not org.valid?
    assert_includes org.errors[:rut], "debe tener formato válido (ej: 76123456-7)"
  end

  test "rejects rut with too many digits" do
    org = organizations(:one)
    org.rut = "111111111-1"
    assert_not org.valid?
    assert_includes org.errors[:rut], "debe tener formato válido (ej: 76123456-7)"
  end
end
