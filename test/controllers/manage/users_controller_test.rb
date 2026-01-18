require "test_helper"

module Manage
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @org_admin = users(:org_admin)
      @org_manager = users(:org_manager)
      @resident = users(:resident)
      @organization = organizations(:one)
    end

    test "org_admin can access manage users" do
      sign_in_as(@org_admin)
      get manage_users_path
      assert_response :success
    end

    test "org_manager cannot access manage users" do
      sign_in_as(@org_manager)
      get manage_users_path
      assert_redirected_to manage_dashboard_index_path
      assert_match(/Solo administradores/, flash[:alert])
    end

    test "org_admin can create user for their organization" do
      sign_in_as(@org_admin)
      assert_difference "User.count" do
        post manage_users_path, params: {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "New",
            last_name: "User",
            role: "org_manager",
            organization_id: @organization.id,
            status: "approved"
          }
        }
      end
      assert_redirected_to manage_users_path
    end

    test "org_admin cannot create user for other organization" do
      sign_in_as(@org_admin)
      other_org = organizations(:two)
      assert_no_difference "User.count" do
        post manage_users_path, params: {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "New",
            last_name: "User",
            role: "org_manager",
            organization_id: other_org.id,
            status: "approved"
          }
        }
      end
      assert_response :unprocessable_entity
    end

    test "resident cannot access manage users" do
      sign_in_as(@resident)
      get manage_users_path
      assert_redirected_to root_path
    end
  end
end
