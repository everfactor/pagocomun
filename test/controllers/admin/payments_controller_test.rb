require "test_helper"

module Admin
  class PaymentsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @super_admin = users(:super_admin)
      @org_admin = users(:org_admin)
      @organization = organizations(:one)
      @unit = Unit.create!(
        organization: @organization,
        number: "101",
        tower: "A",
        pay_day: 5,
        email: "unit101@example.com"
      )
      @bill = Bill.create!(
        unit: @unit,
        amount: 1000,
        period: "2024-01",
        status: "paid"
      )
      @payment = Payment.create!(
        organization: @organization,
        unit: @unit,
        bill: @bill,
        payer_user: users(:resident),
        amount: 1000,
        period: "2024-01",
        status: "authorized",
        parent_buy_order: "P-TEST-001",
        child_buy_order: "TEST-001"
      )
    end

    test "super_admin can view all payments" do
      sign_in_as(@super_admin)
      get admin_payments_path
      assert_response :success
    end

    test "super_admin can view any payment" do
      sign_in_as(@super_admin)
      get admin_payment_path(@payment)
      assert_response :success
    end

    test "org_admin cannot access admin payments" do
      sign_in_as(@org_admin)
      get admin_payments_path
      assert_redirected_to root_path
    end
  end
end
