require "test_helper"

module Admin
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @super_admin = users(:super_admin)
      @org_admin = users(:org_admin)
      @organization = organizations(:one)
    end

    test "super_admin can view all users" do
      sign_in_as(@super_admin)
      get admin_users_path
      assert_response :success
    end

    test "super_admin can create user for any organization" do
      sign_in_as(@super_admin)
      assert_difference "User.count" do
        post admin_users_path, params: {
          user: {
            email_address: "newuser@example.com",
            password: "password123",
            password_confirmation: "password123",
            first_name: "New",
            last_name: "User",
            role: "org_admin",
            organization_id: @organization.id,
            status: "approved"
          }
        }
      end
      assert_redirected_to admin_users_path
    end

    test "org_admin cannot access admin users" do
      sign_in_as(@org_admin)
      get admin_users_path
      assert_redirected_to root_path
    end
  end
end

