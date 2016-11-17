class RenameRecepientInEvents < ActiveRecord::Migration
  def change
    rename_column :events, :recipipient, :recepient
  end
end
