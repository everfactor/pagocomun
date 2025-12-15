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
                          .where(organization_memberships: { user_id: Current.user.id })
                          .distinct
                          .includes(:unit, :user, unit: :organization)
                          .order(created_at: :desc)
      end
    end

    def show
    end

    def new
      @unit_assignment = UnitUserAssignment.new
      @units = if Current.user.role_super_admin?
        Unit.all.order(:number)
      else
        Unit.joins(:organization)
            .where(organizations: { id: Current.user.member_organizations.pluck(:id) })
            .order(:number)
      end
      @users = if Current.user.role_super_admin?
        User.all.order(:email_address)
      else
        User.joins(:member_organizations)
            .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
            .distinct
            .order(:email_address)
      end
    end

    def create
      @unit_assignment = UnitUserAssignment.new(unit_assignment_params)

      if @unit_assignment.save
        respond_to do |format|
          format.html { redirect_to admin_unit_assignments_path, notice: "Unit assignment was successfully created." }
          format.turbo_stream
        end
      else
        @units = if Current.user.role_super_admin?
          Unit.all.order(:number)
        else
          Unit.joins(:organization)
              .where(organizations: { id: Current.user.member_organizations.pluck(:id) })
              .order(:number)
        end
        @users = if Current.user.role_super_admin?
          User.all.order(:email_address)
        else
          User.joins(:member_organizations)
              .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
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
      @units = if Current.user.role_super_admin?
        Unit.all.order(:number)
      else
        Unit.joins(:organization)
            .where(organizations: { id: Current.user.member_organizations.pluck(:id) })
            .order(:number)
      end
      @users = if Current.user.role_super_admin?
        User.all.order(:email_address)
      else
        User.joins(:member_organizations)
            .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
            .distinct
            .order(:email_address)
      end
    end

    def update
      if @unit_assignment.update(unit_assignment_params)
        respond_to do |format|
          format.html { redirect_to admin_unit_assignment_path(@unit_assignment), notice: "Unit assignment was successfully updated." }
          format.turbo_stream
        end
      else
        @units = if Current.user.role_super_admin?
          Unit.all.order(:number)
        else
          Unit.joins(:organization)
              .where(organizations: { id: Current.user.member_organizations.pluck(:id) })
              .order(:number)
        end
        @users = if Current.user.role_super_admin?
          User.all.order(:email_address)
        else
          User.joins(:member_organizations)
              .where(organization_memberships: { organization_id: Current.user.member_organizations.pluck(:id) })
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
      @unit_assignment.destroy
      respond_to do |format|
        format.html { redirect_to admin_unit_assignments_path, notice: "Unit assignment was successfully deleted." }
        format.turbo_stream
      end
    end

    private

    def set_unit_assignment
      @unit_assignment = if Current.user.role_super_admin?
        UnitUserAssignment.find(params[:id])
      else
        UnitUserAssignment.joins(:unit)
                          .joins("INNER JOIN organizations ON units.organization_id = organizations.id")
                          .joins("INNER JOIN organization_memberships ON organizations.id = organization_memberships.organization_id")
                          .where(id: params[:id])
                          .where(organization_memberships: { user_id: Current.user.id })
                          .distinct
                          .first
      end
      redirect_to admin_unit_assignments_path, alert: "Unit assignment not found" unless @unit_assignment
    end

    def unit_assignment_params
      params.require(:unit_user_assignment).permit(:unit_id, :user_id, :starts_on, :ends_on, :active)
    end
  end
end
