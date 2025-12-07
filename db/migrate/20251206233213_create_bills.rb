class CreateBills < ActiveRecord::Migration[8.1]
  def change
    create_table :bills do |t|
      t.references :unit, null: false, foreign_key: true
      t.integer :amount, null: false
      t.date :due_date
      t.string :period                         # "2025-01"
      t.integer :status, default: 0            # 0:pending, 1:paid, 2:failed
      t.boolean :auto_charge, default: false

      t.timestamps
    end
  end
end
