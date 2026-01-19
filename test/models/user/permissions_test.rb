require "test_helper"

class User::PermissionsTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin)
    @org_admin = users(:org_admin)
    @org_manager = users(:org_manager)
    @resident = users(:resident)
    @organization = organizations(:one)
    @other_organization = organizations(:two)
  end

  # Organization permissions
  test "super_admin can manage any organization" do
    assert @super_admin.can_manage_organization?(@organization)
    assert @super_admin.can_manage_organization?(@other_organization)
  end

  test "org_admin can manage their own organization" do
    assert @org_admin.can_manage_organization?(@organization)
  end

  test "org_admin cannot manage other organization" do
    refute @org_admin.can_manage_organization?(@other_organization)
  end

  test "org_manager can manage their own organization" do
    assert @org_manager.can_manage_organization?(@organization)
  end

  test "super_admin can create organization" do
    assert @super_admin.can_create_organization?
  end

  test "org_admin can create organization" do
    assert @org_admin.can_create_organization?
  end

  test "org_manager cannot create organization" do
    refute @org_manager.can_create_organization?
  end

  # User permissions
  test "super_admin can create users for any organization" do
    assert @super_admin.can_create_users_for?(@organization)
    assert @super_admin.can_create_users_for?(@other_organization)
  end

  test "org_admin can create users for their organization" do
    assert @org_admin.can_create_users_for?(@organization)
  end

  test "org_admin cannot create users for other organization" do
    refute @org_admin.can_create_users_for?(@other_organization)
  end

  test "org_manager cannot create users" do
    refute @org_manager.can_create_users_for?(@organization)
  end

  test "org_admin can edit users in their organization" do
    other_user = User.create!(
      email_address: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "org_manager",
      status: "approved"
    )
    @organization.organization_memberships.create!(user: other_user, role: "org_manager", active: true)

    assert @org_admin.can_edit_user?(other_user)
  end

  test "org_admin cannot edit users in other organization" do
    other_user = User.create!(
      email_address: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "org_manager",
      status: "approved"
    )
    @other_organization.organization_memberships.create!(user: other_user, role: "org_manager", active: true)

    refute @org_admin.can_edit_user?(other_user)
  end

  test "org_manager cannot edit users" do
    other_user = User.create!(
      email_address: "other@example.com",
      password: "password123",
      password_confirmation: "password123",
      role: "org_manager",
      status: "approved"
    )
    @organization.organization_memberships.create!(user: other_user, role: "org_manager", active: true)

    refute @org_manager.can_edit_user?(other_user)
  end

  test "user cannot delete themselves" do
    refute @org_admin.can_delete_user?(@org_admin)
  end

  # Unit permissions
  test "super_admin can manage any unit" do
    unit = Unit.create!(organization: @organization, number: "905", tower: "X", pay_day: 5, email: "unit905@example.com")
    assert @super_admin.can_manage_unit?(unit)
  end

  test "org_admin can manage units in their organization" do
    unit = Unit.create!(organization: @organization, number: "906", tower: "X", pay_day: 5, email: "unit906@example.com")
    assert @org_admin.can_manage_unit?(unit)
  end

  test "org_admin cannot manage units in other organization" do
    unit = Unit.create!(organization: @other_organization, number: "907", tower: "X", pay_day: 5, email: "unit907@example.com")
    refute @org_admin.can_manage_unit?(unit)
  end

  # Dashboard permissions
  test "super_admin can access admin dashboard" do
    assert @super_admin.can_access_admin_dashboard?
  end

  test "org_admin cannot access admin dashboard" do
    refute @org_admin.can_access_admin_dashboard?
  end

  test "org_admin can access manage dashboard" do
    assert @org_admin.can_access_manage_dashboard?
  end

  test "org_manager can access manage dashboard" do
    assert @org_manager.can_access_manage_dashboard?
  end

  test "resident cannot access manage dashboard" do
    refute @resident.can_access_manage_dashboard?
  end
end
