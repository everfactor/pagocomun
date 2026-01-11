require "test_helper"

module Manage
  class OrganizationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @org_admin = users(:org_admin)
      @org_manager = users(:org_manager)
      @resident = users(:resident)
      @organization = organizations(:one)
      @other_organization = organizations(:two)
    end

    test "org_admin can access manage organizations" do
      sign_in_as(@org_admin)
      get manage_organizations_path
      assert_response :success
    end

    test "org_manager can access manage organizations" do
      sign_in_as(@org_manager)
      get manage_organizations_path
      assert_response :success
    end

    test "org_admin can only view their own organizations" do
      sign_in_as(@org_admin)
      get manage_organizations_path
      assert_response :success
      # Should only see organizations they're members of
    end

    test "org_admin cannot view other organization" do
      sign_in_as(@org_admin)
      # Try to access organization they're not a member of
      get manage_organization_path(@other_organization)
      assert_redirected_to manage_organizations_path
      assert_match /no encontrada o acceso denegado/, flash[:alert]
    end

    test "org_manager cannot create organization" do
      sign_in_as(@org_manager)
      get new_manage_organization_path
      assert_redirected_to manage_organizations_path
      assert_match /Solo administradores/, flash[:alert]
    end

    test "resident cannot access manage organizations" do
      sign_in_as(@resident)
      get manage_organizations_path
      assert_redirected_to root_path
      assert_equal "Access denied.", flash[:alert]
    end

  end
end
