class PaymentMethodsController < ApplicationController
  before_action :set_user, only: [:create, :finish]
  before_action -> { authorize :payment_method }

  def create
    username  = "USER-#{@user.id}"
    return_url = finish_enrollment_payment_methods_url(user_id: @user.to_gid_param)

    # Start Inscription
    @response = TransbankClient.new.client.start(username, @user.email_address, return_url)
    redirect_to build_url_from_response(@response), allow_other_host: true
  end

  def finish
    # Finish Inscription
    @request = TransbankClient.new.client.finish(params[:TBK_TOKEN])

    # In Oneclick Mall, a successful response code is not always explicitly 0 in the object,
    # but if finish succeeds without error, we treat it as success.
    # The response object contains: tbk_user, authorization_code, card_type, card_number
    if @request["response_code"].to_i == 0
        @user.payment_methods.create!(
          tbk_token: @request["tbk_user"],
          tbk_username: "USER-#{@user.id}",
          card_type: @request["card_type"],
          card_last_4: @request["card_number"]
        )
      redirect_to dashboard_index_path, notice: "Auto-pay activated!"
    else
      redirect_to dashboard_index_path, alert: "Enrollment failed"
    end
  rescue Transbank::Shared::TransbankError => e
      redirect_to dashboard_index_path, alert: "Enrollment error: #{e.message}"
  end


  private

  def set_user
    @user = GlobalID::Locator.locate(params[:user_id])
  end

  def build_url_from_response(response)
    "#{response["url_webpay"]}?TBK_TOKEN=#{response["token"]}"
  end
end
