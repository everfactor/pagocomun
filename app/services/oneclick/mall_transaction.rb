# Placeholder for Transbank OneClick Mall Transaction integration
# TODO: Implement with actual Transbank SDK
# This is a stub that should be replaced with the real Transbank SDK implementation
module Oneclick
  class MallTransaction
    def initialize
      # Initialize Transbank client here
    end

    def init_inscription(username:, email:, response_url:)
      # TODO: Implement actual Transbank OneClick inscription initialization
      # This should call Transbank API to start the enrollment process
      # Returns an object with url and token attributes
      OpenStruct.new(
        url: "#{Rails.application.routes.url_helpers.root_url}payment_methods/finish_enrollment",
        token: "DUMMY_TOKEN_#{SecureRandom.hex(16)}"
      )
    end

    def finish_inscription(token)
      # TODO: Implement actual Transbank OneClick inscription completion
      # This should call Transbank API to complete the enrollment
      # Returns an object with response_code, tbk_user, card_type, card_number attributes
      OpenStruct.new(
        response_code: 0,
        tbk_user: "DUMMY_TBK_USER_#{SecureRandom.hex(16)}",
        card_type: "VISA",
        card_number: "1234"
      )
    end

    def authorize(username:, tbk_user:, buy_order:, details:)
      # TODO: Implement actual Transbank OneClick authorization
      # This should call Transbank API to charge the card
      # Returns an object with response_code and details array
      OpenStruct.new(
        response_code: 0,
        details: [
          OpenStruct.new(
            authorization_code: "AUTH_#{SecureRandom.hex(8)}",
            response_code: 0
          )
        ]
      )
    end
  end
end
