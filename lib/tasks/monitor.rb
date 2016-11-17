#load  'connections.rb'
require 'active_record'
require 'byebug'

TOKEN =  "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJ0aW1lc3RhbXAiOiIyMDE2LTAzLTE2IDE1OjEzOjU0IC0wNzAwIiwiaXNzIjoiRnJvbnRFbmQgU2ltdWxhdG9yIn0."
ActiveRecord::Base.establish_connection(adapter:'postgresql', database:'simulation')#, username: 'gem911dbuser', password: 'pa55word', host:'localhost')
=begin
class User < ActiveRecord::Base
end

class Event < ActiveRecord::Base
end
class Status < ActiveRecord::Base

end
=end

	def monitor
#		Status.first.update(pool_size:10)
		Event.delete_all
#		User.update_all(online:false)
		loop do 
			app.get "/simulation/monitor?token=#{TOKEN}"
#			p "clients online count = " + JSON(app.response.body)["clients_online"].to_s + " **  events count =" +  JSON(app.response.body)["count"].to_s
			p "Users online: #{User.where(online: true).count}, event_count=#{Event.count}"
		#	p "unique clients: " + Event.where(event:'signin').pluck(:user_id).uniq.count.to_s
			sleep 3
		end
	end

