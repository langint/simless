class RenameUserInEvents < ActiveRecord::Migration
  def change
    rename_column :events, :user, :user_id
  end
end
