class CreateSenses < ActiveRecord::Migration
  def change
    create_table :senses do |t|
      t.integer :source_id
      t.integer :target_id
    end
  end
end
