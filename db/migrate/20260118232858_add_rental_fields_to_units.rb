class AddRentalFieldsToUnits < ActiveRecord::Migration[8.1]
  def change
    change_table :units do |t|
      t.date :contract_start_on
      t.string :charge_mode, default: "clp"
      t.string :ipc_adjustment, default: "annual"
      t.decimal :rent_amount, precision: 15, scale: 2
      t.decimal :daily_interest_rate, precision: 5, scale: 2, default: 0
    end
  end
end
