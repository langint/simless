class Dictionary < ApplicationRecord
  has_many :subsets, class_name: 'Dictionary', foreign_key: 'subset_id'
  belongs_to :dictionary, class_name: "Dictionary"
end
