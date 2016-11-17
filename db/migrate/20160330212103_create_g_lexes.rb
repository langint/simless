class CreateGLexes < ActiveRecord::Migration
  def change
    create_table :g_lexes do |t|
      t.string :lex
    end
  end
end
