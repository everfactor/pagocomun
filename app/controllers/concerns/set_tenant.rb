module SetTenant
  extend ActiveSupport::Concern

  included do
    helper_method :current_organization, :current_membership, :effective_role, :scoped_organizations
  end

  def current_organization
    @current_organization ||= Current.user&.organization
  end

  def current_membership
    return unless Current.user && current_organization

    @current_membership ||= OrganizationMembership.find_by(
      organization: current_organization,
      user: Current.user
    )
  end

  # Global base_role can gate platform-wide features; membership role gates org-level features
  def effective_role
    current_membership&.role || :viewer
  end

  def require_organization!
    redirect_to root_path, alert: "Access Denied" unless current_organization
  end

  # Returns organizations the current user has access to
  # - super_admin: all organizations
  # - org_admin/org_manager: only organizations they are members of
  def scoped_organizations
    return Organization.all if Current.user&.role_super_admin?
    return [] unless Current.user

    Current.user.member_organizations
  end

  # Verifies that the user has access to the given organization
  # Raises ActiveRecord::RecordNotFound if access is denied
  def ensure_organization_access!(organization)
    return if Current.user&.role_super_admin?
    return if organization.nil?

    unless scoped_organizations.include?(organization)
      raise ActiveRecord::RecordNotFound, "Organization not found or access denied"
    end
  end
end
