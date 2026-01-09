class PaymentMethodPolicy < ApplicationPolicy
  def create?
    # Logic:
    # 1. User must be logged in (handled by ApplicationController/Pundit context usually, but good to check)
    # 2. User should probably be a resident or org_manager?
    # For now, anyone who can access the dashboard (residents) should be able to enroll a card.
    user.present?
  end

  def finish?
    create?
  end
end
