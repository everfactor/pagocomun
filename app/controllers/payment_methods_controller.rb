class PaymentMethodsController < ApplicationController
  before_action :set_user, only: [:create]

  before_action -> { authorize :payment_method }

  def create
    username  = "USER-#{@user.id}"
    return_url = finish_enrollment_payment_methods_url(user_id: @user.id)

    # Start Inscription
    @response = TransbankClient.new.client.start(
      username,
      @user.email_address,
      return_url
    )

    redirect_to "#{@response['url_webpay']}?TBK_TOKEN=#{@response['token']}", allow_other_host: true
  end

  def finish
    # Finish Inscription
    @req = TransbankClient.new.client.finish(params[:TBK_TOKEN])

    # In Oneclick Mall, a successful response code is not always explicitly 0 in the object,
    # but if finish succeeds without error, we treat it as success.
    # The response object contains: tbk_user, authorization_code, card_type, card_number

    if @req.response_code.to_i == 0
      user_id = params[:user_id] || @req.tbk_user # heuristic if encoded in username
      user = User.find(user_id)

      user.payment_methods.create!(
        tbk_token: @req.tbk_user,
        tbk_username: "USER-#{user.id}", # consistent with create
        card_type: @req.card_type,
        card_last_4: @req.card_number
      )
      redirect_to bills_path, notice: "Auto-pay activated!"
    else
      redirect_to bills_path, alert: "Enrollment failed"
    end
  rescue Transbank::Webpay::WebpayPlus::Exceptions::TransactionCommitError => e
      redirect_to bills_path, alert: "Enrollment error: #{e.message}"
  end


  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
