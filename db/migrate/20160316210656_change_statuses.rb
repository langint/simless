class ChangeStatuses < ActiveRecord::Migration
  def change
    rename_column :statuses, :clients, :pool_size
  end
end
