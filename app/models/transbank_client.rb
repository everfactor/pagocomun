class TransbankClient
  def self.client
    new.client
  end

  def initialize
    # Credentials loaded lazily via private methods
  end

  def client
    @client ||= Transbank::Webpay::Oneclick::MallInscription.new(options)
  end

  def self.mall_transaction
    @mall_transaction ||= new.mall_transaction
  end

  def mall_transaction
    @mall_transaction_inst ||= Transbank::Webpay::Oneclick::MallTransaction.new(options)
  end

  private

  def commerce_code
    @commerce_code ||= Rails.application.credentials.dig(:transbank, :commerce_code)
  end

  def api_key
    @api_key ||= Rails.application.credentials.dig(:transbank, :api_key)
  end

  def tbk_environment
    @tbk_environment ||= Rails.configuration.settings.transbank_environment
  end

  def options
    @options ||= Transbank::Webpay::Options.new(commerce_code, api_key, tbk_environment)
  end
end
