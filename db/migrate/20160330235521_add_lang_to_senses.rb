class AddLangToSenses < ActiveRecord::Migration
  def change
    add_column :senses, :slang, :string
    add_column :senses, :tlang, :string
  end
end
