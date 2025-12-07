class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.string :role, null: false, default: "resident" # enum: super_admin, org_admin, manager, resident
      t.references :organization, null: true, foreign_key: true

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
