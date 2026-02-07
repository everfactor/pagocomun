require "test_helper"

class CMF::IndicatorFetcherTest < ActiveSupport::TestCase
  def setup
    @fetcher = CMF::IndicatorFetcher.new
  end

  test "fetch_uf parses and saves data correctly" do
    target_date = Date.current + 1.day
    uf_payload = {
      "UFs" => [
        {"Valor" => "40.000,00", "Fecha" => target_date.to_s}
      ]
    }

    # Manual mock for call_api
    def @fetcher.call_api(resource)
      @mock_payload
    end
    @fetcher.instance_variable_set(:@mock_payload, uf_payload)

    assert_difference "EconomicIndicator.count", 1 do
      @fetcher.fetch_uf
    end

    indicator = EconomicIndicator.find_by(kind: "uf", date: target_date)
    assert_equal 40000.0, indicator.value
    assert_equal target_date, indicator.date
    assert_equal "CMF", indicator.source
  end

  test "fetch_ipc parses and saves data correctly" do
    target_date = Date.current.beginning_of_month
    ipc_payload = {
      "IPCs" => [
        {"Valor" => "0,5", "Fecha" => target_date.to_s}
      ]
    }

    # Manual mock for call_api
    def @fetcher.call_api(resource)
      @mock_payload
    end
    @fetcher.instance_variable_set(:@mock_payload, ipc_payload)

    assert_difference "EconomicIndicator.count", 1 do
      @fetcher.fetch_ipc
    end

    indicator = EconomicIndicator.latest_ipc
    assert_equal 0.5, indicator.value
    assert_equal target_date, indicator.date
  end

  test "call fetches both uf and ipc" do
    target_uf_date = Date.current + 2.days
    target_ipc_date = Date.current.beginning_of_month + 1.month
    # Manual mock for call_api
    def @fetcher.call_api(resource)
      if resource == "uf"
        {"UFs" => [{"Valor" => "40.000,00", "Fecha" => @target_uf_date.to_s}]}
      else
        {"IPCs" => [{"Valor" => "0,5", "Fecha" => @target_ipc_date.to_s}]}
      end
    end
    @fetcher.instance_variable_set(:@target_uf_date, target_uf_date)
    @fetcher.instance_variable_set(:@target_ipc_date, target_ipc_date)

    assert_difference "EconomicIndicator.count", 2 do
      @fetcher.call
    end
  end
end
