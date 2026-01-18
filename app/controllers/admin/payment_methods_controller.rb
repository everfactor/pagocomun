module Admin
  class PaymentMethodsController < BaseController
    before_action :set_payment_method, only: [:show, :edit, :update, :destroy]

    def index
      @payment_methods = if Current.user.role_super_admin?
        PaymentMethod.includes(unit_user_assignment: [:user, :unit]).order(created_at: :desc)
      else
        PaymentMethod.joins(unit_user_assignment: {unit: :organization})
          .where(units: {organization_id: scoped_organizations.pluck(:id)})
          .includes(unit_user_assignment: [:user, :unit])
          .order(created_at: :desc)
      end
    end

    def show
    end

    def new
      @payment_method = PaymentMethod.new
      prepare_form_data
    end

    def create
      @payment_method = PaymentMethod.new(payment_method_params)

      # Validate assignment belongs to accessible organizations
      if payment_method_params[:unit_user_assignment_id].present?
        assignment = find_accessible_assignment(payment_method_params[:unit_user_assignment_id])
        unless assignment
          @payment_method.errors.add(:unit_user_assignment_id, "is not accessible")
          prepare_form_data
          render_unprocessable :new
          return
        end
      end

      if @payment_method.save
        respond_to do |format|
          format.html { redirect_to admin_payment_methods_path, notice: "Payment method was successfully created." }
          format.turbo_stream
        end
      else
        prepare_form_data
        render_unprocessable :new
      end
    end

    def edit
      prepare_form_data
    end

    def update
      # Validate assignment changes if provided
      if payment_method_params[:unit_user_assignment_id].present? && payment_method_params[:unit_user_assignment_id].to_i != @payment_method.unit_user_assignment_id
        assignment = find_accessible_assignment(payment_method_params[:unit_user_assignment_id])
        unless assignment
          @payment_method.errors.add(:unit_user_assignment_id, "is not accessible")
          prepare_form_data
          render_unprocessable :edit
          return
        end
      end

      if @payment_method.update(payment_method_params)
        respond_to do |format|
          format.html { redirect_to admin_payment_method_path(@payment_method), notice: "Payment method was successfully updated." }
          format.turbo_stream
        end
      else
        prepare_form_data
        render_unprocessable :edit
      end
    end

    def destroy
      @payment_method.destroy
      respond_to do |format|
        format.html { redirect_to admin_payment_methods_path, notice: "Payment method was successfully deleted." }
        format.turbo_stream
      end
    end

    private

    def prepare_form_data
      @assignments = if Current.user.role_super_admin?
        UnitUserAssignment.active.includes(:user, :unit).order("users.email_address")
      else
        UnitUserAssignment.active.joins(unit: :organization)
          .where(units: {organization_id: scoped_organizations.pluck(:id)})
          .includes(:user, :unit)
          .order("users.email_address")
      end
    end

    def find_accessible_assignment(id)
      if Current.user.role_super_admin?
        UnitUserAssignment.find_by(id: id)
      else
        UnitUserAssignment.joins(unit: :organization)
          .where(id: id)
          .where(units: {organization_id: scoped_organizations.pluck(:id)})
          .first
      end
    end

    def render_unprocessable(action)
      respond_to do |format|
        format.html { render action, status: :unprocessable_entity }
        format.turbo_stream { render action, status: :unprocessable_entity }
      end
    end

    def set_payment_method
      @payment_method = if Current.user.role_super_admin?
        PaymentMethod.find_by(id: params[:id])
      else
        PaymentMethod.joins(unit_user_assignment: {unit: :organization})
          .where(id: params[:id])
          .where(units: {organization_id: scoped_organizations.pluck(:id)})
          .first
      end
      unless @payment_method
        redirect_to admin_payment_methods_path, alert: "Payment method not found or access denied"
      end
    end

    def payment_method_params
      params.require(:payment_method).permit(:unit_user_assignment_id, :tbk_username, :tbk_token, :card_last_4, :card_type, :active)
    end
  end
end
