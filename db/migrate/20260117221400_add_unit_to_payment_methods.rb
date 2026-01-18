class AddUnitToPaymentMethods < ActiveRecord::Migration[8.1]
  def change
    add_reference :payment_methods, :unit, null: false, foreign_key: true
  end
end
