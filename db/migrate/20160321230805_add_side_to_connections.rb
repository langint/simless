class AddSideToConnections < ActiveRecord::Migration
  def change
    add_column :connections, :side, :string
  end
end
