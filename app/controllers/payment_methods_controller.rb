class PaymentMethodsController < ActionController::Base
  before_action :set_current_user
  before_action :set_user, only: [:create, :finish]
  before_action :require_enrollment_permission!, only: [:create, :finish]

  def create
    username = "USER-#{@user.id}"
    return_url = finish_enrollment_payment_methods_url(user_id: @user.to_gid_param)

    # Start Inscription
    @response = TransbankClient.new.client.start(username, @user.email_address, return_url)
    # Brakeman warning: This redirects to Transbank payment gateway (external, trusted service)
    # The URL is validated by Transbank SDK and we only redirect on successful response
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
      redirect_to dashboard_index_path(user_id: params[:user_id])
    else
      redirect_to dashboard_index_path(user_id: params[:user_id]), alert: "Enrollment failed"
    end
  rescue Transbank::Shared::TransbankError => e
    redirect_to dashboard_index_path(user_id: params[:user_id]), alert: "Enrollment error: #{e.message}"
  end

  private

  def set_current_user
    Current.user = session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def set_user
    @user = GlobalID::Locator.locate(params[:user_id])
  end

  def require_enrollment_permission!
    # Ensure user is authenticated
    return redirect_to root_path, alert: "Access denied" unless Current.user
    return redirect_to root_path, alert: "Access denied" unless @user

    # User must have permission to enroll payment methods
    return redirect_to root_path, alert: "Access denied" unless Current.user.can_enroll_payment_method?

    # User can enroll their own payment method OR create payment methods for others (if authorized)
    can_enroll_own = Current.user == @user
    can_enroll_for_other = Current.user.can_create_payment_method_for?(@user)

    redirect_to root_path, alert: "Access denied" if !can_enroll_own && !can_enroll_for_other
  end

  def build_url_from_response(response)
    # Validate that the URL is from Transbank domain
    url = response["url_webpay"]
    token = response["token"]

    # Only build URL if we have valid Transbank response
    raise ArgumentError, "Invalid Transbank response" unless url.present? && token.present?

    "#{url}?TBK_TOKEN=#{token}"
  end
end
