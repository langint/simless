class CreateConnections < ActiveRecord::Migration
  def change
    create_table :connections do |t|
      t.string :name
      t.string :address
      t.boolean :ssl
    end
  end
end
