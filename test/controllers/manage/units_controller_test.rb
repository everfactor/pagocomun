require "test_helper"

module Manage
  class UnitsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @org_admin = users(:org_admin)
      @org_manager = users(:org_manager)
      @organization = organizations(:one)
      @other_organization = organizations(:two)
      @unit = Unit.create!(
        organization: @organization,
        number: "101",
        email: "unit101@example.com",
        proration: 1.0
      )
    end

    test "org_admin can view units in their organization" do
      # Ensure units have proration set to avoid nil errors
      @unit.update(proration: 1.0) if @unit.proration.nil?
      sign_in_as(@org_admin)
      get manage_organization_units_path(@organization)
      assert_response :success
    end

    test "org_admin cannot view units in other organization" do
      sign_in_as(@org_admin)
      get manage_organization_units_path(@other_organization)
      assert_redirected_to manage_organizations_path
      assert_match /no encontrada o acceso denegado/, flash[:alert]
    end

    test "org_manager can view units in their organization" do
      # Ensure units have proration set to avoid nil errors
      @unit.update(proration: 1.0) if @unit.proration.nil?
      sign_in_as(@org_manager)
      get manage_organization_units_path(@organization)
      assert_response :success
    end

    test "org_admin can create unit in their organization" do
      sign_in_as(@org_admin)
      assert_difference "Unit.count" do
        post manage_organization_units_path(@organization), params: {
          unit: {
            number: "102",
            email: "unit102@example.com"
          }
        }
      end
    end
  end
end

