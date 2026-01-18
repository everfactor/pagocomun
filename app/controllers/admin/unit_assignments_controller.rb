module Admin
  class UnitAssignmentsController < BaseController
    before_action :set_unit_assignment, only: [:show, :edit, :update, :destroy]

    def index
      @unit_assignments = if Current.user.role_super_admin?
        UnitUserAssignment.includes(:unit, :user, unit: :organization).order(created_at: :desc)
      else
        UnitUserAssignment.joins(:unit)
          .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
          .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
          .where(organization_memberships: {user_id: Current.user.id, organization_id: scoped_organizations.pluck(:id)})
          .distinct
          .includes(:unit, :user, unit: :organization)
          .order(created_at: :desc)
      end

      @pagy, @unit_assignments = pagy(:offset, @unit_assignments)
    end

    def show
    end

    def new
      @unit_assignment = UnitUserAssignment.new
      @units = if Current.user.role_super_admin?
        Unit.all.order(:number)
      else
        Unit.joins(:organization)
          .where(organizations: {id: scoped_organizations.pluck(:id)})
          .order(:number)
      end
      @users = if Current.user.role_super_admin?
        User.all.order(:email_address)
      else
        User.joins(:member_organizations)
          .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
          .distinct
          .order(:email_address)
      end
    end

    def create
      @unit_assignment = UnitUserAssignment.new(unit_assignment_params)

      # Validate unit_id and user_id belong to accessible organizations
      if unit_assignment_params[:unit_id].present?
        unit = if Current.user.role_super_admin?
          Unit.find_by(id: unit_assignment_params[:unit_id])
        else
          Unit.joins(:organization)
            .where(id: unit_assignment_params[:unit_id])
            .where(organizations: {id: scoped_organizations.pluck(:id)})
            .first
        end
        unless unit
          @unit_assignment.errors.add(:unit_id, "is not accessible")
        end
      end

      if unit_assignment_params[:user_id].present?
        user = if Current.user.role_super_admin?
          User.find_by(id: unit_assignment_params[:user_id])
        else
          User.joins(:member_organizations)
            .where(id: unit_assignment_params[:user_id])
            .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
            .distinct
            .first
        end
        unless user
          @unit_assignment.errors.add(:user_id, "is not accessible")
        end
      end

      if @unit_assignment.errors.any? || !@unit_assignment.save
        @units = if Current.user.role_super_admin?
          Unit.all.order(:number)
        else
          Unit.joins(:organization)
            .where(organizations: {id: scoped_organizations.pluck(:id)})
            .order(:number)
        end
        @users = if Current.user.role_super_admin?
          User.all.order(:email_address)
        else
          User.joins(:member_organizations)
            .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
            .distinct
            .order(:email_address)
        end
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
        return
      end

      respond_to do |format|
        format.html { redirect_to admin_unit_assignments_path, notice: "Unit assignment was successfully created." }
        format.turbo_stream
      end
    end

    def edit
      @units = if Current.user.role_super_admin?
        Unit.all.order(:number)
      else
        Unit.joins(:organization)
          .where(organizations: {id: scoped_organizations.pluck(:id)})
          .order(:number)
      end
      @users = if Current.user.role_super_admin?
        User.all.order(:email_address)
      else
        User.joins(:member_organizations)
          .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
          .distinct
          .order(:email_address)
      end
    end

    def update
      # Validate unit_id and user_id changes if provided
      if unit_assignment_params[:unit_id].present? && unit_assignment_params[:unit_id].to_i != @unit_assignment.unit_id
        unit = if Current.user.role_super_admin?
          Unit.find_by(id: unit_assignment_params[:unit_id])
        else
          Unit.joins(:organization)
            .where(id: unit_assignment_params[:unit_id])
            .where(organizations: {id: scoped_organizations.pluck(:id)})
            .first
        end
        unless unit
          @unit_assignment.errors.add(:unit_id, "is not accessible")
        end
      end

      if unit_assignment_params[:user_id].present? && unit_assignment_params[:user_id].to_i != @unit_assignment.user_id
        user = if Current.user.role_super_admin?
          User.find_by(id: unit_assignment_params[:user_id])
        else
          User.joins(:member_organizations)
            .where(id: unit_assignment_params[:user_id])
            .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
            .distinct
            .first
        end
        unless user
          @unit_assignment.errors.add(:user_id, "is not accessible")
        end
      end

      if @unit_assignment.errors.any? || !@unit_assignment.update(unit_assignment_params)
        @units = if Current.user.role_super_admin?
          Unit.all.order(:number)
        else
          Unit.joins(:organization)
            .where(organizations: {id: scoped_organizations.pluck(:id)})
            .order(:number)
        end
        @users = if Current.user.role_super_admin?
          User.all.order(:email_address)
        else
          User.joins(:member_organizations)
            .where(organization_memberships: {organization_id: scoped_organizations.pluck(:id)})
            .distinct
            .order(:email_address)
        end
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.turbo_stream { render :edit, status: :unprocessable_entity }
        end
        return
      end

      respond_to do |format|
        format.html { redirect_to admin_unit_assignment_path(@unit_assignment), notice: "Unit assignment was successfully updated." }
        format.turbo_stream
      end
    end

    def destroy
      @unit_assignment.destroy
      respond_to do |format|
        format.html { redirect_to admin_unit_assignments_path, notice: "Unit assignment was successfully deleted." }
        format.turbo_stream
      end
    end

    private

    def set_unit_assignment
      @unit_assignment = if Current.user.role_super_admin?
        UnitUserAssignment.find_by(id: params[:id])
      else
        UnitUserAssignment.joins(:unit)
          .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
          .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
          .where(id: params[:id])
          .where(organization_memberships: {user_id: Current.user.id, organization_id: scoped_organizations.pluck(:id)})
          .distinct
          .first
      end
      unless @unit_assignment
        redirect_to admin_unit_assignments_path, alert: "Unit assignment not found or access denied"
      end
    end

    def unit_assignment_params
      params.require(:unit_user_assignment).permit(:unit_id, :user_id, :starts_on, :ends_on, :active)
    end
  end
end
