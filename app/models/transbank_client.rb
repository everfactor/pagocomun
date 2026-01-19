class TransbankClient
  COMMERCE_CODE = "597055555541"
  API_KEY = "579B532A7440BB0C9079DED94D31EA1615BACEB56610332264630D42D0A36B1C"
  TBK_ENVIRONMENT = :integration

  def self.client
    new.client
  end

  def initialize
    @commerce_code = COMMERCE_CODE
    @api_key = API_KEY
    @tbk_environment = TBK_ENVIRONMENT
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

  attr_reader :commerce_code, :api_key, :tbk_environment

  def options
    @options ||= Transbank::Webpay::Options.new(commerce_code, api_key, tbk_environment)
  end
end
