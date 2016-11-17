class ChangeEvents < ActiveRecord::Migration
  def change
    add_column :events, :origin, :string
    add_column :events, :recipipient, :string
    add_column :events, :parameters, :string
    remove_column :events, :user_id
  end
end
