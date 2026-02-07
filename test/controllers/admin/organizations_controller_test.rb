require "test_helper"

module Admin
  class OrganizationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @super_admin = users(:super_admin)
      @org_admin = users(:org_admin)
      @organization = organizations(:one)
      @other_organization = organizations(:two)
    end

    test "super_admin can view all organizations" do
      sign_in_as(@super_admin)
      get admin_organizations_path
      assert_response :success
    end

    test "super_admin can view any organization" do
      sign_in_as(@super_admin)
      get admin_organization_path(@organization)
      assert_response :success
    end

    test "super_admin can create organization" do
      sign_in_as(@super_admin)
      assert_difference "Organization.count" do
        post admin_organizations_path, params: {
          organization: {
            name: "New Org",
            rut: "76123456-0",
            org_type: "community",
            status: "approved",
            tbk_child_commerce_code: "597099999999"
          }
        }
      end
      assert_redirected_to admin_organizations_path
    end

    test "org_admin cannot access admin organizations" do
      sign_in_as(@org_admin)
      get admin_organizations_path
      assert_redirected_to root_path
    end
  end
end
