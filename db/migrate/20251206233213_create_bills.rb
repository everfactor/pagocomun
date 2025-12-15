class CreateBills < ActiveRecord::Migration[8.1]
  def change
    create_table :bills do |t|
      t.references :unit, null: false, foreign_key: true
      t.integer :amount, null: false
      t.date :due_date
      t.string :period                         # "2025-01"
      t.string :status, default: "pending"     # pending, paid, failed
      t.boolean :auto_charge, default: false

      t.timestamps
    end
  end
end
