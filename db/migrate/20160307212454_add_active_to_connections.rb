class AddActiveToConnections < ActiveRecord::Migration
  def change
    add_column :connections, :active, :boolean
  end
end
