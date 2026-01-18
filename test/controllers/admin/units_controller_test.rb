require "test_helper"

module Admin
  class UnitsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @super_admin = users(:super_admin)
      @org_admin = users(:org_admin)
      @organization = organizations(:one)
      @other_organization = organizations(:two)
      @unit = Unit.create!(
        organization: @organization,
        number: "101",
        tower: "A",
        pay_day: 5,
        email: "unit101@example.com"
      )
    end

    test "super_admin can view all units" do
      sign_in_as(@super_admin)
      get admin_units_path
      assert_response :success
    end

    test "super_admin can create unit for any organization" do
      sign_in_as(@super_admin)
      assert_difference "Unit.count" do
        post admin_units_path, params: {
          unit: {
            number: "102",
            tower: "A",
            pay_day: 5,
            email: "unit102@example.com",
            organization_id: @organization.id
          }
        }
      end
    end

    test "org_admin cannot access admin units" do
      sign_in_as(@org_admin)
      get admin_units_path
      assert_redirected_to root_path
    end
  end
end
