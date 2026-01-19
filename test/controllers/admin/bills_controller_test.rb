require "test_helper"

module Admin
  class BillsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @super_admin = users(:super_admin)
      @org_admin = users(:org_admin)
      @organization = organizations(:one)
      @unit = Unit.create!(
        organization: @organization,
        number: "902",
        tower: "X",
        pay_day: 5,
        email: "unit902@example.com"
      )
      @bill = Bill.create!(
        unit: @unit,
        amount: 1000,
        period: "2024-01",
        status: "pending"
      )
    end

    test "super_admin can view all bills" do
      sign_in_as(@super_admin)
      get admin_bills_path
      assert_response :success
    end

    test "super_admin can view any bill" do
      sign_in_as(@super_admin)
      get admin_bill_path(@bill)
      assert_response :success
    end

    test "org_admin cannot access admin bills" do
      sign_in_as(@org_admin)
      get admin_bills_path
      assert_redirected_to root_path
    end
  end
end
