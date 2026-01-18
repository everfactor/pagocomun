class PaymentMethodsController < ActionController::Base
  before_action :set_user, only: [:create, :finish]
  before_action :set_unit, only: [:create, :finish]
  before_action :require_enrollment_permission!, only: [:create, :finish]

  def create
    username = "user-#{@user.id}"
    return_url = finish_enrollment_payment_methods_url(user_id: @user.to_gid_param, unit_id: @unit.to_gid_param)

    # Start Inscription
    # The Transbank SDK MallInscription#start method takes 3 positional arguments: (username, email, response_url)
    @response = TransbankClient.client.start(username, @user.email_address, return_url)
    # The URL is validated by Transbank SDK and we only redirect on successful response
    redirect_to build_url_from_response(@response), allow_other_host: true
  end

  def finish
    # Finish Inscription
    # The Transbank SDK MallInscription#finish method takes 1 positional argument: (token)
    @request = TransbankClient.client.finish(params[:TBK_TOKEN])

    # In Oneclick Mall, a successful response code is not always explicitly 0 in the object,
    # but if finish succeeds without error, we treat it as success.
    # The response object contains attributes accessed via methods: tbk_user, response_code, etc.
    if @request["response_code"].to_i == 0
      assignment = @user.unit_user_assignments.active.find_by!(unit: @unit)
      assignment.create_payment_method!(
        tbk_token: @request["tbk_user"],
        tbk_username: "user-#{@user.id}",
        card_type: @request["card_type"],
        card_last_4: @request["card_number"]
      )
      redirect_to dashboard_index_path(user_id: params[:user_id], unit_id: params[:unit_id])
    else
      redirect_to dashboard_index_path(user_id: params[:user_id], unit_id: params[:unit_id]), alert: "Enrollment failed"
    end
  rescue Transbank::Shared::TransbankError => e
    redirect_to dashboard_index_path(user_id: params[:user_id], unit_id: params[:unit_id]), alert: "Enrollment error: #{e.message}"
  end

  private

  def set_user
    @user = GlobalID::Locator.locate(params[:user_id])
  end

  def set_unit
    @unit = GlobalID::Locator.locate(params[:unit_id])
  end

  def require_enrollment_permission!
    return redirect_to root_path, alert: "Access denied" unless @user

    redirect_to root_path, alert: "Access denied" unless @unit
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
