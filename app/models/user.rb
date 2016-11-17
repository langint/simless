class User < ActiveRecord::Base
  belongs_to :psap_detail
  has_many :events

  def self.online_count
  	self.where(online: true).count
  end

end
