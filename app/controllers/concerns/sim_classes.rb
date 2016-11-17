require 'active_support/concern'

module SimClasses
	extend ActiveSupport::Concern
	require 'faker'

	def launch
		loop do
			logger.warn Thread.list.count
			if stop?
				logger.warn "Stopping..."
				break
			end
			session_messages = rand(3..8)
			session_duration = rand(4..8)
			session_id = Faker::Code.ean
			start_session session_messages, session_id
			sleep 1
		end
		puts "Stopped"
	end

  		def start_session(num_messages, session)
			Thread.new do 
				Thread.current[:message] = "datra"
				counter = 0
				while counter < num_messages
		#			puts "Counter = #{counter}, session = #{session}, message = #{Thread.current[:message]}"
					counter += 1
					sleep rand(1..2)
				end
				 puts "Terminating session #{session} #{Thread.current}"
			end
		end

def stop?
	@stopping
end

def terminate
	@stopping = 'stop'
end

	class Simulation
  	#	attr_accessor :continue
  		
  		def launch
			loop do
				session_messages = rand(3..8)
				session_duration = rand(4..8)
				session_id = Faker::Code.ean
				start_session session_messages, session_id
				sleep 3
			end
  		end

  		def start_session(num_messages, session)
			session = Thread.new do 
				counter = 0
				while counter < num_messages
					Thread.current[:message] = "Session #{session} " + Faker::Lorem.word
				#	puts "Counter = #{counter}, session = #{session}, message = #{Thread.current[:message]}"
					counter += 1
					sleep rand(1..2)
				end
				 puts "Terminating session #{session} #{Thread.current}"
			end
		end

		def terminate
			Thread.list.each do |thread|
				thread.exit unless thread == Thread.current
			end
		end
  	end


end