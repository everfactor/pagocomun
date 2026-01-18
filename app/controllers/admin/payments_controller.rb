module Admin
  class PaymentsController < BaseController
    before_action :set_payment, only: [:show]

    def index
      @organizations = scoped_organizations
      @payments = if Current.user.role_super_admin?
        Payment.all
      else
        Payment.joins(:organization)
          .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
          .where(organization_memberships: {user_id: Current.user.id, organization_id: scoped_organizations.pluck(:id)})
          .distinct
      end

      @payments = @payments.includes(:organization, :unit, :bill, :payer_user, :payment_method).order(created_at: :desc)

      if params[:organization_id].present?
        @payments = @payments.where(organization_id: params[:organization_id])
      end

      if params[:period].present?
        @payments = @payments.where(period: params[:period])
      end
    end

    def show
    end

    private

    def set_payment
      @payment = if Current.user.role_super_admin?
        Payment.find_by(id: params[:id])
      else
        Payment.joins(:organization)
          .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
          .where(id: params[:id])
          .where(organization_memberships: {user_id: Current.user.id, organization_id: scoped_organizations.pluck(:id)})
          .distinct
          .first
      end
      unless @payment
        redirect_to admin_payments_path, alert: "Payment not found or access denied"
      end
    end
  end
end
