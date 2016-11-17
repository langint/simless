class CreateDictionaries < ActiveRecord::Migration
  def change
    create_table :dictionaries do |t|
      t.string :name
      t.references :subset, index: true
      t.timestamp
    end
  end
end
