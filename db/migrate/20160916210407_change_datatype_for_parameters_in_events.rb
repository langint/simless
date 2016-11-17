class ChangeDatatypeForParametersInEvents < ActiveRecord::Migration
  def change
    remove_column :events, :parameters
    add_column :events, :parameters, :text
  end
end
