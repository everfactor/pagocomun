module Manage
  class PaymentsController < BaseController
    before_action :set_payment, only: [:show]

    def index
      @payments = Payment.joins(:organization)
        .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
        .where(organization_memberships: {user_id: Current.user.id})
        .distinct
        .includes(:organization, :unit, :bill, :payer_user, :payment_method)
        .order(created_at: :desc)
    end

    def show
    end

    private

    def set_payment
      @payment = Payment.joins(:organization)
        .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
        .where(id: params[:id])
        .where(organization_memberships: {user_id: Current.user.id})
        .distinct
        .first
      redirect_to manage_payments_path, alert: "Pago no encontrado" unless @payment
    end
  end
end
