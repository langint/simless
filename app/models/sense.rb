class Sense < ActiveRecord::Base
  belongs_to :e_lex, foreign_key: :source_id
  belongs_to :r_lex, foreign_key: :target_id
end

