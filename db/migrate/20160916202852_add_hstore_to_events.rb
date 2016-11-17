class AddHstoreToEvents < ActiveRecord::Migration
  def change
    remove_column :events, :parameters
    add_column :events, :parameters, :hstore
  end
end
