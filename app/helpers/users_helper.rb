module UsersHelper
  def available_roles_for_select
    if Current.user.role_super_admin?
      [
        [t("enums.user.role.super_admin"), "super_admin"],
        [t("enums.user.role.org_admin"), "org_admin"],
        [t("enums.user.role.org_manager"), "org_manager"]
      ]
    else
      [
        [t("enums.user.role.org_manager"), "org_manager"],
        [t("enums.user.role.org_admin"), "org_admin"]
      ]
    end
  end

  def organization_select_config(require_organization: false)
    require_org = require_organization || request.path.include?("/manage/")
    organizations = Current.user.role_super_admin? ? Organization.all : Current.user.member_organizations
    select_options = require_org ? {} : {prompt: t("helpers.select.prompt")}

    select_attributes = {
      class: "block w-full rounded-md border-0 px-3 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-blue-600 sm:text-sm"
    }
    select_attributes[:required] = true if require_org

    {
      organizations: organizations,
      select_options: select_options,
      select_attributes: select_attributes,
      required: require_org
    }
  end
end
