class CreateChargeRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :charge_runs do |t|
      t.references :organization, null: true, foreign_key: true
      t.references :triggered_by, null: true, foreign_key: {to_table: :users}
      t.string :run_type, null: false, default: "scheduled"
      t.string :status, null: false, default: "pending"
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :total_bills, default: 0
      t.integer :successful_charges, default: 0
      t.integer :failed_charges, default: 0
      t.integer :skipped_charges, default: 0
      t.text :error_message

      t.timestamps
    end

    # Indexes for organization_id and triggered_by_id are automatically created by t.references
    add_index :charge_runs, :status
    add_index :charge_runs, :run_type
    add_index :charge_runs, :created_at
  end
end
