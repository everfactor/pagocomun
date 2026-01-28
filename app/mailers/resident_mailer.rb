class ResidentMailer < ApplicationMailer
  def enrollment_email(user)
    @user = user
    @url = public_enrollment_url(token: user.signed_token)

    mail(to: user.email_address, subject: "Bienvenido a PagoComún - Activa el Pago Automático")
  end
end
