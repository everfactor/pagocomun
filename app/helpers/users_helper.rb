module UsersHelper
  def available_roles_for_select
    if Current.user.role_super_admin?
      [
        [t('enums.user.role.super_admin'), 'super_admin'],
        [t('enums.user.role.org_admin'), 'org_admin'],
        [t('enums.user.role.org_manager'), 'org_manager']
      ]
    else
      [
        [t('enums.user.role.org_manager'), 'org_manager'],
        [t('enums.user.role.org_admin'), 'org_admin']
      ]
    end
  end
end
