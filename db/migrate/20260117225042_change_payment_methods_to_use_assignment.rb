class ChangePaymentMethodsToUseAssignment < ActiveRecord::Migration[8.1]
  def change
    # Clean up previous indices
    remove_index :payment_methods, name: "idx_pm_user_unit_token" if index_exists?(:payment_methods, name: "idx_pm_user_unit_token")
    remove_index :payment_methods, name: "index_payment_methods_on_user_id_and_tbk_token" if index_exists?(:payment_methods, name: "index_payment_methods_on_user_id_and_tbk_token")

    # Remove old references
    remove_reference :payment_methods, :user, foreign_key: true
    remove_reference :payment_methods, :unit, foreign_key: true

    # Add new reference to UnitUserAssignment
    add_reference :payment_methods, :unit_user_assignment, null: false, foreign_key: true

    # Add unique index for assignment and token
    add_index :payment_methods, [:unit_user_assignment_id, :tbk_token], unique: true, name: "idx_pm_assignment_token"
  end
end
