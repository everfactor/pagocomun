module NavigationHelper
  def admin_nav_items
    [
      {
        name: "Dashboard",
        path: admin_dashboard_index_path,
        icon: :dashboard
      },
      {
        name: "Organizations",
        path: admin_organizations_path,
        icon: :organizations
      },
      {
        name: "Users",
        path: admin_users_path,
        icon: :users
      },
      {
        name: "Units",
        path: admin_units_path,
        icon: :units
      },
      {
        name: "Bills",
        path: admin_bills_path,
        icon: :bills
      },
      {
        name: "Payments",
        path: admin_payments_path,
        icon: :payments
      },
      {
        name: "Payment Methods",
        path: admin_payment_methods_path,
        icon: :payment_methods
      },
      {
        name: "Unit Assignments",
        path: admin_unit_assignments_path,
        icon: :assignments
      }
    ]
  end

  def current_nav_item?(path)
    request.path == path || request.path.start_with?(path + "/")
  end

  def admin_organizations
    return [] unless Current.user

    if Current.user.role_super_admin?
      Organization.all
    else
      Current.user.member_organizations
    end
  end

  def nav_item_classes(is_active)
    base_classes = "group flex gap-x-3 rounded-md p-2 text-sm/6 font-semibold"
    if is_active
      "#{base_classes} bg-gray-50 text-blue-600"
    else
      "#{base_classes} text-gray-700 hover:bg-gray-50 hover:text-blue-600"
    end
  end

  def nav_icon_classes(is_active)
    base_classes = "size-6 shrink-0"
    if is_active
      "#{base_classes} text-blue-600"
    else
      "#{base_classes} text-gray-400 group-hover:text-blue-600"
    end
  end
end
