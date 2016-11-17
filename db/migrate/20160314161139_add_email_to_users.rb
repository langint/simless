class AddEmailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :email, :string, index: true
  end
end
