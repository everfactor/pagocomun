class UpdatePaymentMethodsIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index :payment_methods, name: "index_payment_methods_on_user_id_and_tbk_token"
    add_index :payment_methods, [:user_id, :unit_id, :tbk_token], unique: true, name: "idx_pm_user_unit_token"
  end
end
