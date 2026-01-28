module Manage
  class ChargeRunsController < BaseController
    before_action :set_charge_run, only: [:show, :export]
    before_action :ensure_organization_access!, only: [:show, :export]

    def index
      # Show charge runs for organizations the user has access to
      organization_ids = scoped_organizations.pluck(:id)
      @charge_runs = ChargeRun.recent
        .where(organization_id: organization_ids)
        .includes(:organization, :triggered_by)

      if params[:organization_id].present?
        org = scoped_organizations.find_by(id: params[:organization_id])
        if org
          @charge_runs = @charge_runs.where(organization_id: org.id)
        else
          redirect_to manage_charge_runs_path, alert: "Organización no encontrada o sin acceso"
          return
        end
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
      organization = scoped_organizations.find_by(id: params[:organization_id])
      unless organization
        redirect_to manage_charge_runs_path, alert: "Organización no encontrada o sin acceso"
        return
      end

      OrganizationChargeJob.perform_later(organization, Current.user.id)
      redirect_to manage_charge_runs_path, notice: "Corrida de cobro iniciada para #{organization.name}"
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
        redirect_to manage_charge_run_path(@charge_run), alert: "Formato no soportado"
      end
    end

    private

    def set_charge_run
      @charge_run = ChargeRun.find(params[:id])
    end

    def ensure_organization_access!
      return unless @charge_run.organization

      ensure_organization_access!(@charge_run.organization)
    end
  end
end
