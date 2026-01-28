class OrganizationChargeJob < ApplicationJob
  queue_as :default

  def perform(organization, triggered_by_user_id = nil)
    OrganizationCharge::Runner.call(organization:, triggered_by_user_id:)
  end
end
