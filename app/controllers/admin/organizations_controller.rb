module Admin
  class OrganizationsController < BaseController
    before_action :set_organization, only: [:show, :edit, :update, :destroy]

    def index
      @organizations = scoped_organizations.order(created_at: :desc)
    end

    def show
    end

    def new
      @organization = Organization.new
    end

    def create
      @organization = Organization.new(organization_params)
      @organization.status = "approved"

      # Validate owner_id belongs to accessible organizations if provided
      if @organization.owner_id.present?
        owner = User.find_by(id: @organization.owner_id)
        unless owner && (Current.user.role_super_admin? || scoped_organizations.any? { |org| org.members.include?(owner) })
          @organization.errors.add(:owner_id, "is not accessible")
          respond_to do |format|
            format.html { render :new, status: :unprocessable_entity }
          end
          return
        end
      end

      if @organization.save
        # Associate the owner if provided (usually by org_admin)
        if @organization.owner_id.present?
          owner = User.find(@organization.owner_id)
          @organization.organization_memberships.create!(user: owner, role: "org_admin", active: true)
          # Also set the organization_id on the user for the has_one :owner association
          owner.update!(organization: @organization) if owner.organization_id.nil?
        end

        respond_to do |format|
          format.html { redirect_to admin_organizations_path, notice: "Organization was successfully created." }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
    end

    def update
      # Validate owner_id changes if provided
      if organization_params[:owner_id].present? && organization_params[:owner_id] != @organization.owner&.id.to_s
        new_owner = User.find_by(id: organization_params[:owner_id])
        unless new_owner && (Current.user.role_super_admin? || scoped_organizations.any? { |org| org.members.include?(new_owner) })
          @organization.errors.add(:owner_id, "is not accessible")
          respond_to do |format|
            format.html { render :edit, status: :unprocessable_entity }
          end
          return
        end
      end

      if @organization.update(organization_params)
        respond_to do |format|
          format.html { redirect_to admin_organization_path(@organization), notice: "Organization was successfully updated." }
        end
      else
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @organization.destroy
      respond_to do |format|
        format.html { redirect_to admin_organizations_path, notice: "Organization was successfully deleted." }
      end
    end

    private

    def set_organization
      @organization = scoped_organizations.find_by(id: params[:id])
      unless @organization
        redirect_to admin_organizations_path, alert: "Organization not found or access denied"
      end
    end

    def organization_params
      params.require(:organization).permit(:name, :rut, :slug, :active, :org_type, :address, :tbk_child_commerce_code, :note, :owner_id).with_defaults(status: "approved")
    end
  end
end
