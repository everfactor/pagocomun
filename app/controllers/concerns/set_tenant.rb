module SetTenant
  extend ActiveSupport::Concern

  included do
    helper_method :current_organization, :current_membership, :effective_role
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
end
