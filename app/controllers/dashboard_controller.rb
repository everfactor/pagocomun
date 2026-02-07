class DashboardController < ApplicationController
  def index
    if Current.user&.role_super_admin?
      redirect_to admin_dashboard_index_path and return
    elsif Current.user&.role_org_admin? || Current.user&.role_org_manager?
      redirect_to manage_dashboard_index_path and return
    end

    @token = params[:token]
    @user = User.locate_signed(@token) || GlobalID::Locator.locate(params[:user_id])

    @active_assignments = @user.unit_user_assignments.active.includes(unit: :organization)

    # Load all bills for all assigned units
    assigned_unit_ids = @active_assignments.map(&:unit_id)
    all_bills = Bill.where(unit_id: assigned_unit_ids).includes(unit: :organization).order(period: :desc)

    # Calculate stats per unit (using all bills, not paginated)
    @unit_stats = {}
    @active_assignments.each do |assignment|
      unit = assignment.unit
      unit_bills = all_bills.select { |b| b.unit_id == unit.id }

      @unit_stats[unit.id] = {
        total: unit_bills.count,
        pending: unit_bills.count { |b| b.status == "pending" },
        paid: unit_bills.count { |b| b.status == "paid" },
        total_pending_amount: unit_bills.select { |b| b.status == "pending" }.sum(&:amount)
      }
    end

    # Paginate bills for the table
    @pagy, @all_bills = pagy_array(all_bills.to_a, limit: 15)

    @payments = @user.payments.order(created_at: :desc).limit(5)
  end
end
