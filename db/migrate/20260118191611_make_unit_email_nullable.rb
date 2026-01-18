class MakeUnitEmailNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :units, :email, true
  end
end
