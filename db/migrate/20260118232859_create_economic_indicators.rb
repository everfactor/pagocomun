class CreateEconomicIndicators < ActiveRecord::Migration[8.1]
  def change
    create_table :economic_indicators do |t|
      t.string :kind, null: false
      t.decimal :value, precision: 15, scale: 2, null: false
      t.date :date, null: false
      t.string :source
      t.jsonb :raw_payload

      t.timestamps
    end

    add_index :economic_indicators, :kind
    add_index :economic_indicators, :date
    add_index :economic_indicators, [:kind, :date], unique: true
  end
end
