class ChargeNotificationMailer < ApplicationMailer
  def payment_rejected(charge_attempt, user)
    @charge_attempt = charge_attempt
    @bill = charge_attempt.bill
    @unit = @bill.unit
    @organization = @bill.organization
    @user = user

    mail(to: user.email_address, subject: "Pago Rechazado - #{@organization.name}")
  end

  def technical_error(charge_attempt, user)
    @charge_attempt = charge_attempt
    @bill = charge_attempt.bill
    @unit = @bill.unit
    @organization = @bill.organization
    @user = user

    mail(to: user.email_address, subject: "Error Técnico en Cobro - #{@organization.name}")
  end

  def daily_summary(charge_run, user)
    @charge_run = charge_run
    @organization = charge_run.organization
    @user = user

    mail(to: user.email_address, subject: "Resumen Diario de Cobros - #{@organization&.name || "Todas las Organizaciones"}")
  end
end
