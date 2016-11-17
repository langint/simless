class AddOnlineToUser < ActiveRecord::Migration
  def change
    add_column :users, :online, :boolean
    add_column :users, :psap, :string
  end
end
