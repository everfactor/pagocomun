class RemoveTransbankIdFromOrganizations < ActiveRecord::Migration[8.1]
  def change
    remove_column :organizations, :transbank_id, :string
  end
end
