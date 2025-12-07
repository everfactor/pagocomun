class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :bill, null: false, foreign_key: true
      t.references :payment_method, null: true, foreign_key: true

      t.references :payer_user, null: false, foreign_key: { to_table: :users }

      t.string :period, null: false
      t.integer :amount, null: false

      # TBK (Mall OneClick)
      t.string :parent_buy_order, null: false
      t.string :child_buy_order, null: false
      t.string :tbk_auth_code
      t.integer :response_code
      t.string :status, null: false, default: "initiated" # initiated, authorized, failed, reversed, refunded

      t.jsonb :gateway_payload

      t.timestamps
    end

    add_index :payments, :parent_buy_order, unique: true
    add_index :payments, :child_buy_order, unique: true
  end
end
