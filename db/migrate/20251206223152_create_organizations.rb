class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :rut, null: false
      t.string :slug
      t.boolean :active, default: true

      # Organization type: 0: community (e.g., HOA/condo), 1: rental_space (space/asset rental)
      t.integer :org_type, null: false, default: 0

      # Unique Transbank identifier for the org
      t.string :transbank_id, null: false

      t.timestamps
    end

    add_index :organizations, :slug
    add_index :organizations, :transbank_id, unique: true
  end
end
