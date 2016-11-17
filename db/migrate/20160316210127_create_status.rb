class CreateStatus < ActiveRecord::Migration
  def change
    create_table :statuses do |t|
      t.integer :clients
      t.string :status
      t.integer :ramp_up
      t.integer :refresh_interval
      t.integer :conv_day
      t.integer :mess_day
    end
  end
end
