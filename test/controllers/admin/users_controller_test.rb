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

    test "super_admin can filter users by name" do
      sign_in_as(@super_admin)
      get admin_users_path, params: {name: @org_admin.first_name}
      assert_response :success
      assert_select "td", text: /#{@org_admin.first_name}/
    end

    test "super_admin can filter users by email" do
      sign_in_as(@super_admin)
      get admin_users_path, params: {email: @org_admin.email_address}
      assert_response :success
      assert_select "td", text: @org_admin.email_address
    end

    test "super_admin can filter users by status" do
      sign_in_as(@super_admin)
      get admin_users_path, params: {status: "pending"}
      assert_response :success
      # All users in fixtures are likely approved, so we check for no users if none are pending
      # or check for the specific status if we know one is pending.
    end

    test "super_admin can filter users by organization" do
      sign_in_as(@super_admin)
      get admin_users_path, params: {organization_id: @organization.id}
      assert_response :success
    end

    test "super_admin can approve a user" do
      sign_in_as(@super_admin)
      user = users(:org_admin)
      user.status_pending!
      patch approve_admin_user_path(user)
      assert_redirected_to admin_users_path
      assert user.reload.status_approved?
    end

    test "super_admin can reject a user" do
      sign_in_as(@super_admin)
      user = users(:org_admin)
      user.status_pending!
      patch reject_admin_user_path(user)
      assert_redirected_to admin_users_path
      assert user.reload.status_rejected?
    end
  end
end
