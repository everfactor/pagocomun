require "test_helper"

class ChargeAttemptTest < ActiveSupport::TestCase
  setup do
    @charge_run = charge_runs(:one)
    @bill = bills(:one)
    @attempt = ChargeAttempt.new(
      charge_run: @charge_run,
      bill: @bill,
      status: :pending,
      error_type: :none
    )
  end

  test "should be valid" do
    assert @attempt.valid?
  end

  test "should require status" do
    @attempt.status = nil
    assert_not @attempt.valid?
  end

  test "should require error_type" do
    @attempt.error_type = nil
    assert_not @attempt.valid?
  end

  test "mark_success! should update status and payment" do
    @attempt.save!
    payment = payments(:one)

    @attempt.mark_success!(payment)

    assert_equal "success", @attempt.status
    assert_equal payment, @attempt.payment
    assert_equal "none", @attempt.error_type
    assert_not @attempt.retryable
  end

  test "mark_failed! should update status and error info" do
    @attempt.save!

    @attempt.mark_failed!(:connection, "Connection timeout", nil, retryable: true)

    assert_equal "failed", @attempt.status
    assert_equal "connection", @attempt.error_type
    assert_equal "Connection timeout", @attempt.error_message
    assert @attempt.retryable
  end

  test "mark_rejected! should update status and mark as not retryable" do
    @attempt.save!

    @attempt.mark_rejected!("Payment rejected", -1)

    assert_equal "rejected", @attempt.status
    assert_equal "rejected", @attempt.error_type
    assert_not @attempt.retryable
  end

  test "mark_skipped! should update status" do
    @attempt.save!

    @attempt.mark_skipped!("No payment method")

    assert_equal "skipped", @attempt.status
    assert_equal "No payment method", @attempt.error_message
    assert_not @attempt.retryable
  end
end
