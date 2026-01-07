class AddContactDataToUnits < ActiveRecord::Migration[8.1]
  def change
    add_column :units, :email, :string
    add_column :units, :mobile_number, :string
    add_index :units, :email
  end
end
