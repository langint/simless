class ApiController < ApplicationController
PROXY_USERNAME = 'test'
PROXY_PASSWORD = 'test'
PROXY_URL = "http://10.32.85.102:11486/"
GWA_URL = "http://10.32.95.14:11380/"
HOME_PSAP = "T29095999"
OPERATORS = ["qalatsyrC", "kansop22", "kansop95", "maingop93", "maingop36", "xynailimixaM", "maingop53", "maingop95", "xyeropmet", 
	"kansop94", "maingop68", "kansop3", "kansop11", "kansop40", "leebw", "kansop70", "kansop92", "maingop39", "xydeserunt", "qaquia", "maingop30"]

	def index
		render plain: 'index'
	end

	def show
		case params[:id]
		when 'proxy_call'
			complete_transfer
			render plain: 'proxy_to-gwa'
		end
	
	end

	def recent_calls
		Event.create(event:'recent_calls_request', origin: 'gwa', recepient: 'gwp', parameters: params.except("controller", "action"))
#		logger.info params['TCS.QueryConversationHistory']
		gwa_request = params['TCS.QueryConversationHistory'.to_sym]
        psap = gwa_request["TCS.PSAPId"]
        start_time = Time.at(gwa_request["TCS.startDate"].to_i / 1000 )
        end_time = Time.at(gwa_request["TCS.endDate"].to_i / 1000 )
        delivery = {"TCS.QueryConversationHistoryResult" => {"TCS.messages"=>[]} }
        Runtime.where(psap_id: psap).each do |m|
	 		mes = m.as_json.except("id", "psap_id")
	 		mes.keys.each{|k| mes["TCS." + k] = mes[k].to_s; mes.delete(k)} # Renaming keys
	 		mes.keys.each{|k| mes[k.camelize] = mes[k]}
	 		mes["TCS.date"] = mes["TCS.date"]
	 		message = mes.except("TCS.session_id", "TCS.operator_login", "TCS.message_id") #getting rid of incorrectly renamed keys
	        delivery["TCS.QueryConversationHistoryResult"]["TCS.messages"] << message 
		end
		delivery["TCS.QueryConversationHistoryResult"]["TCS.status"] = 1
		json_obj = JSON.generate(delivery)
		logger.info json_obj
		render plain: json_obj
	end

	def create # Transfer action
		Event.create(event:'transfer_request', origin: 'gwa', recepient: 'gwp', parameters: params.except("controller", "action"))
		target_id = params["TCS.TransferSession"]["TCS.targetPsapId"]
		logger.warn "Create - target_id: #{target_id}"
		session_id = params["TCS.TransferSession"]["TCS.sessionId"]
		Thread.new{sleep 2; complete_transfer(target_id, session_id)} # In 2 seconds complete the transfer on the simulated GWP side and inform GWA on completion
		Thread.new do # Making a new session to replenish to the list of available sessions
			sleep 6; 
			new_session 
		end
		render json: {"TCS.transferSessionResponse":"true"} # Informing GWA that the transfer has been requested 
	end

	def complete_transfer target, session
		# Record the current session with PSAP A to Runtime so that it stays in the history
	#	create_transfer_messages HOME_PSAP, session
		url = "txt911api/update_conversation"
		start_time = rand(10..100)
		content = {
			"TCS.psapid": HOME_PSAP,
			"TCS.carrierId":"verizon",
			"TCS.sessionId":session,
			"TCS.sessionState":6,
			"TCS.dateStart": start_time.minutes.ago.strftime("%a %b %d %H:%M:%S UTC %Y"),
			"TCS.dateEnd": (start_time +10).minutes.ago.strftime("%a %b %d %H:%M:%S UTC %Y"),
			"TCS.callbackNum":"4102220000",
			"TCS.mostRecentLoc":{"TCS.lat":47609700,"TCS.lon":-122333100,"TCS.hUncert":2500,"TCS.mlpPosMethod":"CELL"},
			"TCS.sessionTransferTarget":{"TCS.psapid":target,"TCS.psapname":""},
			"TCS.messsages":[]
			}
		logger.warn "Target: #{target}, session: #{session} "
		json_obj = JSON.generate content
		create_transfer_messages(target, session) # Create new session with the same id for the target psap and populate it with messages on simulated Runtime 
		resp = proxy_to_gwa_post url, json_obj
	end

	def proxy_to_gwa_post url, content
		uri_string = GWA_URL + url
		uri = URI(uri_string)
		req = Net::HTTP::Post.new(uri.path)
		req.body = content
		req["Content-Type"] = "application/json"
		req.basic_auth PROXY_USERNAME, PROXY_PASSWORD
		Event.create(event:'post_to_gwa', origin: 'gwp', recepient: 'gwa', parameters: content)
		http = Net::HTTP.new(uri.host, uri.port)
		http.set_debug_output($stdout)
		resp = http.start {|htt|htt.request(req)}
	end



	def new_session
		url = "txt911api/new_conversation"
		content = make_new_session
		proxy_to_gwa_post url, JSON.generate(content)
		render plain: 'here'
	end

	private
	
	def make_new_session psap_id = HOME_PSAP
		content = JSON.parse File.read("lib/documents/new_session.json")
		session_id = Faker::Number.hexadecimal(24).upcase
		content["TCS.psapid"] = psap_id
		content["TCS.sessionId"] = session_id
		content["TCS.sessionState"] = 3
		content["TCS.dateStart"] = 5.seconds.ago.strftime("%a %b %d %H:%M:%S UTC %Y")
		content["TCS.callbackNum"] = Faker::PhoneNumber.phone_number.gsub(/\sx.*/,"").gsub(/[()-.]/, "") 
    	content["TCS.messsages"] = make_messages session_id, rand(4..10)
    	content
	end

	def make_messages session, num = 4, psap_id = HOME_PSAP
		id_pool = num.times.map{Faker::Number.hexadecimal(24).upcase}
		messages = []
		num.times do |it| 
			phone = Faker::PhoneNumber.phone_number.gsub(/\sx.*/,"").gsub(/[()-.]/, "")
			operator_login = it == 0 ? "tcstestuser12" : operator
			if it.odd?
				call_from = phone
				call_to = '911'
			else
				call_from = '911'
				call_to = phone
			end
			messages <<  { "TCS.date" => rand(3..10).seconds.ago.strftime("%a %b %d %H:%M:%S UTC %Y"), "TCS.from" => call_from, 
							"TCS.text" => Faker::Lorem.sentence, "TCS.psapid" => psap_id, "TCS.messageId" => id_pool.pop, 
							"TCS.sessionId" => session, "TCS.operatorLogin" => "tcstestuser12", "TCS.to" => call_to
	        		}
		end
		messages
	end

	def create_transfer_messages target_id, session_id
		phone = Faker::PhoneNumber.phone_number.gsub(/[()-.]/, "").gsub(/\sx\d*$/,"").gsub(/\s/, "")
		operator_login = OPERATORS.shuffle.first
		4.times do |it|
			rec = Runtime.new
			rec.operator_login = it < 2 ? "tcstestuser12" : operator_login
#			rec.operator_login = operator_login
			rec.date = rand(30..600).seconds.ago.in_time_zone("America/Chicago")
			rec.from = it.odd? ? '911' : phone
			rec.to = it.even? ? '911' : phone
			rec.message_id =  Faker::Number.hexadecimal(24).upcase
			rec.session_id = session_id
			rec.status = 4
			rec.psap_id = it < 2 ? HOME_PSAP : target_id
			rec.text = Faker::Lorem.sentence
			record = rec.save
		end
	end
end
