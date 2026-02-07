require "test_helper"

class Bill::ChargerTest < ActiveSupport::TestCase
  setup do
    @bill = bills(:one)
    @bill.update(status: "pending")
    @unit = @bill.unit
    @organization = @unit.organization
    @user = users(:resident)
    @payment_method = payment_methods(:one)

    # Unit already has assignment via fixtures (one)
    @assignment = unit_user_assignments(:one)
  end

  test "successful authorization creates payment with economic indicators" do
    # Mock Transbank response as hash (matching actual Transbank response structure)
    mock_response = {
      "details" => [
        {
          "response_code" => 0,
          "authorization_code" => "AUTH123"
        }
      ]
    }

    # Manual stub for TransbankClient.mall_transaction
    class << TransbankClient
      alias_method :original_mall_transaction, :mall_transaction
      def mall_transaction
        @mock_client
      end
      attr_accessor :mock_client
    end

    mock_client = Object.new
    mock_client.define_singleton_method(:authorize) { |*args| mock_response }
    TransbankClient.mock_client = mock_client

    # Mock indicators
    latest_uf = economic_indicators(:uf_today)
    latest_ipc = economic_indicators(:ipc_last_month)

    begin
      assert_difference "Payment.count", 1 do
        result = Bill::Charger.new(@bill).call
        assert result.success?
      end
    ensure
      # Restore
      class << TransbankClient
        remove_method :mall_transaction
        alias_method :mall_transaction, :original_mall_transaction
        remove_method :original_mall_transaction
      end
    end

    payment = Payment.last
    assert_equal "authorized", payment.status
    assert_equal latest_uf.value, payment.economic_snapshot["uf_value"].to_d
    assert_equal latest_ipc.value, payment.economic_snapshot["ipc_value"].to_d
    assert_equal latest_uf.date.to_s, payment.economic_snapshot["indicator_date"]
    assert @bill.reload.status_paid?
  end

  test "failed authorization does not create payment" do
    mock_response = {
      "details" => [
        {
          "response_code" => -1
        }
      ]
    }

    # Manual stub for TransbankClient.mall_transaction
    class << TransbankClient
      alias_method :original_mall_transaction, :mall_transaction
      def mall_transaction
        @mock_client
      end
      attr_accessor :mock_client
    end

    mock_client = Object.new
    mock_client.define_singleton_method(:authorize) { |*args| mock_response }
    TransbankClient.mock_client = mock_client

    begin
      assert_no_difference "Payment.count" do
        result = Bill::Charger.new(@bill).call
        refute result.success?
      end
    ensure
      # Restore
      class << TransbankClient
        remove_method :mall_transaction
        alias_method :mall_transaction, :original_mall_transaction
        remove_method :original_mall_transaction
      end
    end

    assert @bill.reload.status_failed?
  end
end
