require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "format_rut formats 8-digit RUT with dots" do
    assert_equal "76.123.456-7", format_rut("76123456-7")
  end

  test "format_rut formats 7-digit RUT with dots" do
    assert_equal "1.111.111-K", format_rut("1111111-K")
  end

  test "format_rut preserves check digit K" do
    assert_equal "11.111.111-K", format_rut("11111111-K")
  end

  test "format_rut preserves numeric check digit" do
    assert_equal "76.123.456-7", format_rut("76123456-7")
  end

  test "format_rut preserves check digit 0" do
    assert_equal "11.111.111-0", format_rut("11111111-0")
  end

  test "format_rut handles nil gracefully" do
    assert_nil format_rut(nil)
  end

  test "format_rut handles empty string gracefully" do
    assert_nil format_rut("")
  end

  test "format_rut handles blank string gracefully" do
    assert_nil format_rut("   ")
  end

  test "format_rut returns original if no dash present" do
    assert_equal "invalid", format_rut("invalid")
  end

  test "format_rut formats 9-digit RUT correctly" do
    # Edge case: some RUTs might have 9 digits in the body (rare but possible)
    assert_equal "111.111.111-1", format_rut("111111111-1")
  end
end
