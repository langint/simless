class AddColumnTimestampToEvents < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.timestamps null: false
    end
  end
end
