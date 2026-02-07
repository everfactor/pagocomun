# Custom validator for Chilean RUT (Rol Único Tributario)
# Validates format (XXXXXXXX-Y) and check digit using modulo 11 algorithm
#
# Usage:
#   validates :rut, rut: true
class RutValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    # Format validation: XXXXXXXX-Y without dots
    unless value.match?(/\A\d{7,8}-[0-9kK]\z/i)
      record.errors.add(attribute, "debe tener formato válido (ej: 76123456-7)")
      return
    end

    # Check digit validation using modulo 11 algorithm
    body, check_digit = value.upcase.split("-")

    sum = 0
    multiplier = 2

    body.reverse.each_char do |digit|
      sum += digit.to_i * multiplier
      multiplier = multiplier == 7 ? 2 : multiplier + 1
    end

    expected_digit = case 11 - (sum % 11)
    when 11 then "0"
    when 10 then "K"
    else (11 - (sum % 11)).to_s
    end

    unless check_digit == expected_digit
      record.errors.add(attribute, "tiene un dígito verificador inválido")
    end
  end
end
