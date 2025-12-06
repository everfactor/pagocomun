class PaymentMethodsController < ApplicationController
  include SetTenant

  before_action :set_user, only: [:create]
  before_action :require_organization!

  def create
    username  = "USER-#{@user.id}"
    email     = @user.email_address
    return_url = finish_enrollment_payment_methods_url(user_id: @user.id) # define this route

    response = Oneclick::MallTransaction.new.init_inscription(
      username: username,
      email: email,
      response_url: return_url
    )

    redirect_to "#{response.url}?TBK_TOKEN=#{response.token}", allow_other_host: true
  end

  def finish
    req = Oneclick::MallTransaction.new.finish_inscription(params[:TBK_TOKEN])

    if req.response_code == 0
      # If your return flow includes user_id param, prefer that; otherwise, parse req.username
      user_id = params[:user_id] || req.username.to_s.sub("USER-", "").to_i
      user = User.find(user_id)

      user.payment_methods.create!(
        tbk_token: req.tbk_user,
        tbk_username: "USER-#{user.id}",
        card_type: req.card_type,
        card_last_4: req.card_number
      )
      redirect_to bills_path, notice: "Auto-pay activated!"
    else
      redirect_to bills_path, alert: "Enrollment failed"
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end
end
