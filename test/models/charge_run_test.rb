require "test_helper"

class ChargeRunTest < ActiveSupport::TestCase
  setup do
    @organization = organizations(:one)
    @charge_run = ChargeRun.new(
      organization: @organization,
      run_type: :scheduled,
      status: :pending
    )
  end

  test "should be valid" do
    assert @charge_run.valid?
  end

  test "should require run_type" do
    @charge_run.run_type = nil
    assert_not @charge_run.valid?
  end

  test "should require status" do
    @charge_run.status = nil
    assert_not @charge_run.valid?
  end

  test "start! should update status and started_at" do
    @charge_run.save!
    @charge_run.start!

    assert_equal "running", @charge_run.status
    assert_not_nil @charge_run.started_at
  end

  test "complete! should update status and calculate stats" do
    @charge_run.save!
    attempt1 = charge_attempts(:success)
    attempt1.update!(charge_run: @charge_run)
    attempt2 = charge_attempts(:failed)
    attempt2.update!(charge_run: @charge_run)

    @charge_run.complete!

    assert_equal "completed", @charge_run.status
    assert_not_nil @charge_run.completed_at
    assert_equal 2, @charge_run.total_bills
  end

  test "summary_stats should return correct counts" do
    @charge_run.save!
    attempt = charge_attempts(:success)
    attempt.update!(charge_run: @charge_run)

    stats = @charge_run.summary_stats

    assert_equal 1, stats[:total]
    assert_equal 1, stats[:successful]
  end
end
