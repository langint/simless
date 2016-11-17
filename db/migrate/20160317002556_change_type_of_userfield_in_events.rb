class ChangeTypeOfUserfieldInEvents < ActiveRecord::Migration
  def change
    remove_column :events, :user
    add_column :events, :user, :integer
  end
end
