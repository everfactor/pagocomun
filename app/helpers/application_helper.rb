module ApplicationHelper
  def format_rut(rut)
    return if rut.blank?

    # Split RUT into body and check digit
    body, check_digit = rut.split("-")
    return rut unless body && check_digit

    # Format body with dots (e.g., "76123456" → "76.123.456")
    formatted_body = body.reverse.scan(/.{1,3}/).join(".").reverse

    "#{formatted_body}-#{check_digit}"
  end
end
