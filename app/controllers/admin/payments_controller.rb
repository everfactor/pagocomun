module Admin
  class PaymentsController < BaseController
    before_action :set_payment, only: [:show]

    def index
      @payments = if Current.user.role_super_admin?
        Payment.includes(:organization, :unit, :bill, :payer_user, :payment_method).order(created_at: :desc)
      else
        Payment.joins(:organization)
               .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
               .where(organization_memberships: { user_id: Current.user.id })
               .distinct
               .includes(:organization, :unit, :bill, :payer_user, :payment_method)
               .order(created_at: :desc)
      end
    end

    def show
    end

    private

    def set_payment
      @payment = if Current.user.role_super_admin?
        Payment.find(params[:id])
      else
        Payment.joins(:organization)
               .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
               .where(id: params[:id])
               .where(organization_memberships: { user_id: Current.user.id })
               .distinct
               .first
      end
      redirect_to admin_payments_path, alert: "Payment not found" unless @payment
    end
  end
end
