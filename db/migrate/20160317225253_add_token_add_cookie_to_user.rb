class AddTokenAddCookieToUser < ActiveRecord::Migration
  def change
    add_column :users, :token, :string
    add_column :users, :cookie, :string
  end
end
