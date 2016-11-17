class CreateRuntime < ActiveRecord::Migration
  def change
    create_table :runtimes do |t|
      t.datetime :date
      t.string :from
      t.string :to
      t.string :message_id
      t.string :operator_login
      t.text :text
      t.integer :status
    end
  end
end
