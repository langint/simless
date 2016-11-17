class RenameMessDayInStatuses < ActiveRecord::Migration
  def change
    rename_column :statuses, :mess_day, :mess_conv
  end
end
