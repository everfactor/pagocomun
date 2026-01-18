class AddFieldsToUnitsAndOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :units, :pay_day, :integer
    add_column :units, :name, :string
    add_column :organizations, :last_bill_upload_period, :string
  end
end
