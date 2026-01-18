# Test helper to mock Transbank calls
require "transbank/sdk"

module TransbankTestHelper
  def mock_oneclick_inscription_start(token: "mock_token", url: "http://mock.url")
    response = Transbank::Webpay::Oneclick::MallInscription::Response.new({"token" => token, "url" => url})
    Transbank::Webpay::Oneclick::MallInscription.stub(:create, response) do
      yield
    end
  end

  def mock_oneclick_inscription_finish(token: "mock_token", tbk_user: "mock_tbk_user", card_type: "Visa", card_number: "1234", response_code: 0)
    response = Transbank::Webpay::Oneclick::MallInscription::FinishResponse.new({
      "tbk_user" => tbk_user,
      "auth_code" => "123456",
      "card_type" => card_type,
      "card_number" => card_number,
      "response_code" => response_code
    })
    Transbank::Webpay::Oneclick::MallInscription.stub(:finish, response) do
      yield
    end
  end
end
