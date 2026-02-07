class CreateChargeAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :charge_attempts do |t|
      t.references :charge_run, null: false, foreign_key: true
      t.references :bill, null: false, foreign_key: true
      t.references :payment, null: true, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :error_type, default: "none"
      t.text :error_message
      t.integer :response_code
      t.integer :retry_count, default: 0
      t.boolean :retryable, default: false

      t.timestamps
    end

    # Indexes for charge_run_id, bill_id, and payment_id are automatically created by t.references
    add_index :charge_attempts, :status
    add_index :charge_attempts, :error_type
    add_index :charge_attempts, :retryable
  end
end
