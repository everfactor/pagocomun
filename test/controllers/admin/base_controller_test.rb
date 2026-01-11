require "test_helper"

module Admin
  class BaseControllerTest < ActionDispatch::IntegrationTest
    test "super_admin can access admin routes" do
      user = users(:super_admin)
      sign_in_as(user)

      get admin_dashboard_index_path
      assert_response :success
    end

    test "org_admin cannot access admin routes" do
      user = users(:org_admin)
      sign_in_as(user)

      get admin_dashboard_index_path
      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "org_manager cannot access admin routes" do
      user = users(:org_manager)
      sign_in_as(user)

      get admin_dashboard_index_path
      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "resident cannot access admin routes" do
      user = users(:resident)
      sign_in_as(user)

      get admin_dashboard_index_path
      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

    test "unauthenticated user cannot access admin routes" do
      get admin_dashboard_index_path
      assert_redirected_to root_path
      assert_equal "Access denied. Admin privileges required.", flash[:alert]
    end

  end
end
