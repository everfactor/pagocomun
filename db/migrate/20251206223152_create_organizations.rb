class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :rut, null: false
      t.string :slug
      t.boolean :active, default: true

      # Status: pending, approved, rejected
      t.string :status, null: false, default: "pending"
      t.text :note, comment: "Note for approval/rejection tracking"

      # Organization type: community (e.g., HOA/condo), rental_space (space/asset rental)
      t.string :org_type, null: false, default: "community"

      # Unique Transbank identifier for the org
      t.string :transbank_id, null: false

      # Fields moved from communities
      t.string :address
      t.string :tbk_child_commerce_code, comment: "Provided by Transbank per organization"

      t.timestamps
    end

    add_index :organizations, :slug
    add_index :organizations, :transbank_id, unique: true
  end
end
