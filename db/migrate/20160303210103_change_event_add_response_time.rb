class ChangeEventAddResponseTime < ActiveRecord::Migration
  def change
    add_column :events, :response_time, :float
  end
end
