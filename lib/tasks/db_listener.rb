require 'active_record'
	
class Session < ActiveRecord::Base
	self.table_name = 'sessions'
end

ActiveRecord::Base.establish_connection(adapter:'mysql', database:'gem911db', username: 'gem911dbuser', password: 'pa55word', host:'localhost')

def listen_database
	start_id = Session.last.id
	start_time = Time.now
	start_count, last_id = Session.count, Session.last.id
#	file = File.open("db_statistics.txt", "a")
	counter = 0
	puts Session.last.id
	loop do
		puts "Last Session ID: #{Session.last.id}"
		sleep 3
=begin		
		transactions = Session.last.id - start_id
		increase = (Session.count - start_count).to_i
		unless increase == 0
			puts "**** At #{5* counter} sec: accumulation rate = #{ (increase/(Time.now - start_time)).to_i} rec/sec, #{transactions} transactions"
	#		file.puts "#{5*counter} : #{ (increase/ (Time.now - start_time)).to_i} : #{transactions}" 
			sleep 5
			counter += 1

		end
=end	
	end
end

listen_database
