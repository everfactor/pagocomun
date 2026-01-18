class ResidentMailer < ApplicationMailer
  def enrollment_email
    @user = params[:user]
    @token = @user.to_sgid(expires_in: 30.days, for: "enrollment").to_s
    @url = public_enrollment_url(token: @token)

    mail(to: @user.email_address, subject: "Bienvenido a PagoComún - Activa el Pago Automático")
  end
end
