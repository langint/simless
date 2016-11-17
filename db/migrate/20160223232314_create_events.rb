class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :user
      t.string :event
      t.string :response_code
    end
  end
end
