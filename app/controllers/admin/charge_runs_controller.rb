module Admin
  class ChargeRunsController < BaseController
    before_action :set_charge_run, only: [:show, :export]

    def index
      @charge_runs = ChargeRun.recent.includes(:organization, :triggered_by)

      if params[:organization_id].present?
        @charge_runs = @charge_runs.where(organization_id: params[:organization_id])
      end

      if params[:status].present?
        @charge_runs = @charge_runs.where(status: params[:status])
      end

      @pagy, @charge_runs = pagy(:offset, @charge_runs)
      @organizations = scoped_organizations
    end

    def show
      @charge_attempts = @charge_run.charge_attempts
        .includes(:bill, :payment, bill: [:unit, :organization])
        .order(created_at: :desc)

      if params[:status].present?
        @charge_attempts = @charge_attempts.where(status: params[:status])
      end

      @pagy, @charge_attempts = pagy(:offset, @charge_attempts)
    end

    def create
      if params[:organization_id].present?
        organization = scoped_organizations.find_by(id: params[:organization_id])
        unless organization
          redirect_to admin_charge_runs_path, alert: "Organización no encontrada o sin acceso"
          return
        end
        OrganizationChargeJob.perform_later(organization, Current.user.id)
        redirect_to admin_charge_runs_path, notice: "Corrida de cobro iniciada para #{organization.name}"
      else
        # Trigger manual charge for all organizations
        OrganizationChargeJob.perform_later(nil, Current.user.id)
        redirect_to admin_charge_runs_path, notice: "Corrida de cobro iniciada para todas las organizaciones"
      end
    end

    def export
      format = params[:format]&.to_sym || :csv
      exporter = ChargeRun::Exporter.new(@charge_run, format: format)

      case format
      when :csv
        send_data exporter.export, filename: "charge_run_#{@charge_run.id}_#{Date.current}.csv", type: "text/csv"
      when :xlsx
        send_data exporter.export, filename: "charge_run_#{@charge_run.id}_#{Date.current}.xlsx", type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      else
        redirect_to admin_charge_run_path(@charge_run), alert: "Formato no soportado"
      end
    end

    private

    def set_charge_run
      @charge_run = ChargeRun.find(params[:id])
    end
  end
end
