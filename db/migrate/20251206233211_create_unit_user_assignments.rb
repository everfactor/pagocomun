class CreateUnitUserAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :unit_user_assignments do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true  # the payer user
      t.date :starts_on, null: false
      t.date :ends_on, null: true
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :unit_user_assignments, [:unit_id, :user_id, :starts_on], name: "idx_unit_user_assign_hist"
  end
end
