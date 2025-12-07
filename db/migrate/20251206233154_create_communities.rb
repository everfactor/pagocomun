class CreateCommunities < ActiveRecord::Migration[8.1]
  def change
    create_table :communities do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address
      # Provided by Transbank per building
      t.string :tbk_child_commerce_code, null: false, comment: "Provided by Transbank per building"

      t.timestamps
    end
  end
end
