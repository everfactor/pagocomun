module Admin
  class PaymentMethodsController < BaseController
    before_action :set_payment_method, only: [:show, :edit, :update, :destroy]

    def index
      @payment_methods = if Current.user.role_super_admin?
        PaymentMethod.includes(:user).order(created_at: :desc)
      else
        PaymentMethod.joins(:user)
                     .joins("INNER JOIN organization_memberships ON users.id = organization_memberships.user_id")
                     .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
                     .distinct
                     .includes(:user)
                     .order(created_at: :desc)
      end
    end

    def show
    end

    def new
      @payment_method = PaymentMethod.new
      @users = if Current.user.role_super_admin?
        User.all.order(:email_address)
      else
        User.joins(:member_organizations)
            .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
            .distinct
            .order(:email_address)
      end
    end

    def create
      @payment_method = PaymentMethod.new(payment_method_params)

      # Validate user_id belongs to accessible organizations
      if payment_method_params[:user_id].present?
        user = if Current.user.role_super_admin?
          User.find_by(id: payment_method_params[:user_id])
        else
          User.joins(:member_organizations)
              .where(id: payment_method_params[:user_id])
              .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
              .distinct
              .first
        end
        unless user
          @payment_method.errors.add(:user_id, "is not accessible")
          @users = if Current.user.role_super_admin?
            User.all.order(:email_address)
          else
            User.joins(:member_organizations)
                .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
                .distinct
                .order(:email_address)
          end
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
            format.turbo_stream { render :new, status: :unprocessable_entity }
          end
          return
        end
      end

      if @payment_method.save
        respond_to do |format|
          format.html { redirect_to admin_payment_methods_path, notice: "Payment method was successfully created." }
          format.turbo_stream
        end
      else
        @users = if Current.user.role_super_admin?
          User.all.order(:email_address)
        else
          User.joins(:member_organizations)
              .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
              .distinct
              .order(:email_address)
        end
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      @users = if Current.user.role_super_admin?
        User.all.order(:email_address)
      else
        User.joins(:member_organizations)
            .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
            .distinct
            .order(:email_address)
      end
    end

    def update
      # Validate user_id changes if provided
      if payment_method_params[:user_id].present? && payment_method_params[:user_id].to_i != @payment_method.user_id
        user = if Current.user.role_super_admin?
          User.find_by(id: payment_method_params[:user_id])
        else
          User.joins(:member_organizations)
              .where(id: payment_method_params[:user_id])
              .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
              .distinct
              .first
        end
        unless user
          @payment_method.errors.add(:user_id, "is not accessible")
          @users = if Current.user.role_super_admin?
            User.all.order(:email_address)
          else
            User.joins(:member_organizations)
                .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
                .distinct
                .order(:email_address)
          end
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_entity }
            format.turbo_stream { render :edit, status: :unprocessable_entity }
          end
          return
        end
      end

      if @payment_method.update(payment_method_params)
        respond_to do |format|
          format.html { redirect_to admin_payment_method_path(@payment_method), notice: "Payment method was successfully updated." }
          format.turbo_stream
        end
      else
        @users = if Current.user.role_super_admin?
          User.all.order(:email_address)
        else
          User.joins(:member_organizations)
              .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
              .distinct
              .order(:email_address)
        end
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
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

    def set_payment_method
      @payment_method = if Current.user.role_super_admin?
        PaymentMethod.find_by(id: params[:id])
      else
        PaymentMethod.joins(:user)
                     .joins("INNER JOIN organization_memberships ON users.id = organization_memberships.user_id")
                     .where(id: params[:id])
                     .where(organization_memberships: { organization_id: scoped_organizations.pluck(:id) })
                     .distinct
                     .first
      end
      unless @payment_method
        redirect_to admin_payment_methods_path, alert: "Payment method not found or access denied"
      end
    end

    def payment_method_params
      params.require(:payment_method).permit(:user_id, :tbk_username, :tbk_token, :card_last_4, :card_type, :active)
    end
  end
end
