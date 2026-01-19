class AddEconomicSnapshotToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :economic_snapshot, :jsonb, default: {}
  end
end
