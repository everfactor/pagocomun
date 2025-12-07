class CreatePaymentMethods < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_methods do |t|
      t.references :user, null: false, foreign_key: true
      t.string :tbk_username, null: false    # Distinct ID sent to TBK
      t.string :tbk_token, null: false       # Token for future charges
      t.string :card_last_4
      t.string :card_type
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :payment_methods, [:user_id, :tbk_token], unique: true
  end
end
