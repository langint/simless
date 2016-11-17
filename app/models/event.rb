class Event < ActiveRecord::Base
  belongs_to :user
	def onliner?
		self.user.online
	end
end
