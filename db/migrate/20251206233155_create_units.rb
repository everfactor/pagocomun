class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :community, null: false, foreign_key: true
      t.string :number, null: false
      t.string :tower
      t.float :proration

      t.timestamps
    end

    add_index :units, [:community_id, :number, :tower], unique: true, name: "idx_units_unique_key"
  end
end
