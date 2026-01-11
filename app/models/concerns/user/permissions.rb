module User::Permissions
  extend ActiveSupport::Concern

  # Organization-level permissions
  def can_manage_organization?(organization)
    return true if role_super_admin?
    return false unless organization
    member_organizations.include?(organization)
  end

  def can_create_organization?
    # Super admins can create any organization
    # Org admins can create organizations (they become members)
    role_super_admin? || role_org_admin?
  end

  def can_edit_organization?(organization)
    can_manage_organization?(organization)
  end

  def can_delete_organization?(organization)
    can_manage_organization?(organization)
  end

  # User-level permissions
  def can_create_users_for?(organization)
    return true if role_super_admin?
    return false unless organization
    # Only org_admins can create users, and only for their organizations
    role_org_admin? && member_organizations.include?(organization)
  end

  def can_edit_user?(other_user)
    return true if role_super_admin?
    return false unless other_user
    return false if role_org_manager? # Managers can't edit users
    return false if role_resident? # Residents can't edit users
    # Org admins can edit users in their organizations
    role_org_admin? && shares_organization_with?(other_user)
  end

  def can_delete_user?(other_user)
    return true if role_super_admin?
    return false unless other_user
    return false if other_user == self # Can't delete yourself
    can_edit_user?(other_user)
  end

  def can_view_user?(other_user)
    return true if role_super_admin?
    return false unless other_user
    # Can view users in same organizations
    shares_organization_with?(other_user)
  end

  # Unit-level permissions
  def can_manage_unit?(unit)
    return true if role_super_admin?
    return false unless unit
    can_manage_organization?(unit.organization)
  end

  def can_create_unit?(organization)
    return true if role_super_admin?
    return false unless organization
    can_manage_organization?(organization)
  end

  def can_edit_unit?(unit)
    can_manage_unit?(unit)
  end

  def can_delete_unit?(unit)
    can_manage_unit?(unit)
  end

  # Bill-level permissions
  def can_view_bill?(bill)
    return true if role_super_admin?
    return false unless bill
    can_manage_organization?(bill.organization)
  end

  def can_manage_bills_for?(organization)
    return true if role_super_admin?
    return false unless organization
    can_manage_organization?(organization)
  end

  # Payment-level permissions
  def can_view_payment?(payment)
    return true if role_super_admin?
    return false unless payment
    can_manage_organization?(payment.organization)
  end

  def can_manage_payments_for?(organization)
    return true if role_super_admin?
    return false unless organization
    can_manage_organization?(organization)
  end

  # Payment Method permissions
  def can_manage_payment_method?(payment_method)
    return true if role_super_admin?
    return false unless payment_method
    # Can manage payment methods for users in accessible organizations
    user = payment_method.user
    return false unless user
    shares_organization_with?(user)
  end

  def can_create_payment_method_for?(target_user)
    return true if role_super_admin?
    return false unless target_user
    # Can create payment methods for users in accessible organizations
    shares_organization_with?(target_user)
  end

  def can_enroll_payment_method?
    # Residents and org_managers can enroll their own payment methods
    role_resident? || role_org_manager? || role_org_admin? || role_super_admin?
  end

  # Unit Assignment permissions
  def can_manage_unit_assignment?(unit_assignment)
    return true if role_super_admin?
    return false unless unit_assignment
    unit = unit_assignment.unit
    return false unless unit
    can_manage_organization?(unit.organization)
  end

  def can_create_unit_assignment?(unit, target_user)
    return true if role_super_admin?
    return false unless unit && target_user
    # Can create assignments for units and users in accessible organizations
    can_manage_organization?(unit.organization) && shares_organization_with?(target_user)
  end

  # Dashboard permissions
  def can_access_dashboard?
    # Any authenticated user can access their dashboard
    true
  end

  def can_access_admin_dashboard?
    role_super_admin?
  end

  def can_access_manage_dashboard?
    role_org_admin? || role_org_manager? || role_super_admin?
  end

  private

  def shares_organization_with?(other_user)
    return false unless other_user
    (member_organizations & other_user.member_organizations).any?
  end
end
