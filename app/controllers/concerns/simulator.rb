require 'active_support/concern'

module Simulator
	extend ActiveSupport::Concern
	require 'uri'
	require 'resolv-replace.rb'

	ENVIRONMENT = "LAB" # Set it either "PRE" or "LAB"
	SSL = false
	URL_ADDRESS = ENVIRONMENT == "LAB" ? "smsdev-gemapp1.sealab.telecomsys.com:8080" : "smspre-est-gemapp1.xypoint.com:8080"
	REFRESH_RATE = 5.0
	MONITOR_RATE = 3
	SHOW_SIGNIN_RESPONSE = false
	SHOW_REFRESH_RESPONSE = false
	HTTPS_ADDRESS = "172.31.4.77"
	USERS_LIST = 'lib/users_psaps.yml'
	PW44 = "fw3P3BBgfHazva1gXC3KkQ%2C1%2C0dwQgxw2Efk%2Cf1T8XXrYl8nfAVgE0qVTug"
	PW55 = "v5viztbjI%2FDJ6WVAt1aotw%2C1%2CE7pX8RHlRtA%2CnwsV74ZtlBUb23x2rBenBA"

	@max_pool = YAML.load_file('lib/users_psaps.yml').size
	SIM_ENV_SOURCE = "lib/settings.yml"
	SIM_ENV = YAML.load_file("lib/settings.yml").map!{|a| a.symbolize_keys}
	API_MESSAGES = JSON( File.read("lib/api.json") )	
	
	def self.sim_environments
		YAML.load_file(SIM_ENV_SOURCE).map!{|a| a.symbolize_keys}	
	end

	def self.default_env
		Simulator.sim_environments.detect{|e| e[:default]}
	end

	def self.pool_size
		YAML.load_file('lib/users_psaps.yml').size
	end

	class Sim
		
		
		def initialize(env)
			@connections = env[:connections].symbolize_keys
			@failures = 0
		end

		def start_simulation
			User.update_all(online: false)
			Event.delete_all
	#		pool_size = Status.first.pool_size || 10
			@conn = @connections[:front]
	      	@host = @conn["url"]
	      	@protocol = @conn["ssl"] ? 'https' : 'http'
	     	refresh_calls = Thread.new{ refresh_loop}
	      	register_clients
		end

		def register_clients
			user_list = User.where(online: false).to_a
			while user_list.size > 0 && Status.first.pool_size > User.online_count
	    		user = user_list.pop
		    	call_time = Time.now     		
	     		begin
	 				response = Timeout.timeout(5){ sign_in user }
	 				return if response.nil?
	 				Event.create( user_id: user[:id], event: 'signin', response_code: response.code, response_time: (Time.now - call_time) )
	 				user.update(online: true)
	 			rescue Timeout::Error
	 				Event.create(user_id: user[:id], event: 'failure', response_code: '500', response_time: (Time.now - call_time) )
	 			end	
		    	ramp_up_interval = 1.0 / Status.first.ramp_up
	      		sleep ramp_up_interval
	      	end
		end

		def refresh_loop
			pause = Status.first.refresh_interval || 5
			mutex = Mutex.new
			loop do
				Thread.current.kill unless Rails.cache.read('sim_status') == 'running'
				refresh_interval = rand( (pause * 0.9)..(pause  * 1.1) )
				User.where("online = ? and updated_at < ?", true, refresh_interval.seconds.ago).shuffle.each do |user|
					Thread.new do 
						mutex.lock
						user.updated_at = Time.now
						user.save
						refresh( user )
						mutex.unlock
					end
				end
		#		p Event.count
				sleep 1
			end
		end

		def refresh user
			call_attr = {verb: "post", user: user, page: '/queues/queue_refresh', req_body: "psap_id=#{user[:psap]}"}		
			call_time = Time.now
			begin
				response = http_call(call_attr)
				hash = {user_id: user[:id], event: 'refresh', response_code: response.code, response_time: (Time.now - call_time) }
				sim_connection "Event.create(#{hash})"
			rescue
				hash = {user_id: user[:login], event: 'failure', response_code: response.code, response_time: (Time.now - call_time) }
				sim_connection "Event.create(#{hash})" 
			end
		end	


		def change_load
			delta = Status.first.pool_size - User.online_count
			delta > 0 ? increase_load(delta.abs) : decrease_load(delta.abs)
		end

		def increase_load delta
			@host = @conn["url"]
	      	@protocol = @conn["ssl"] ? 'https' : 'http'
	      	users_online = User.where(online:true).pluck(:login)
	      	user_list = get_users.reject{|u| users_online.include? u[:login]}
	      	while user_list.size > 0 && (users_online.count + delta) > User.where(online: true).count  do
	      		user = user_list.pop
	      		call_time = Time.now
	      		begin
	 				response = Timeout.timeout(3){ sign_in user }
	 			rescue Timeout::Error
	 				ActiveRecord::Base.connection_pool.with_connection do
						Event.create(user_id: user[:id], event: 'failure', response_code: '500', response_time: (Time.now - call_time) )
					end
	 				next
	 			end
	   #   		start_client_calls(user)
	      		ramp_up_interval = 1.0 / Status.first.ramp_up
	      		sleep ramp_up_interval
	      	end
		end

		def decrease_load delta
			User.where(online:true).order("RANDOM()").limit(delta).update_all(online: false)
		end

		def connection_test(env = 2, conn_id = "front")
			@host = @connections[conn_id.to_sym]["url"]
			@protocol = @connections[conn_id.to_sym]["ssl"] ? 'https' : 'http'
	      	@conn = @connections[conn_id.to_sym]
	      	( pre_sign_in =~ /^_session/ ).nil? ? 'Failure' : 'Success'
		end

		private

		def sign_in(user)
			user.update(cookie: pre_sign_in)
	 		call_attr = {verb: "get", user: user, page: '/users/sign_in', req_body: ""}  		# Obtaining the sign-in page with the csrf token 
	 		response = http_call(call_attr)
			password = user[:password] == "pa44word" ? PW44 : PW55
			user.token = Nokogiri::XML(response.body).xpath("//head/meta[@name='csrf-token']").last.attributes["content"].value		
			# Signing in (POST)
			req_body = "utf8=%E2%9C%93&authenticity_token=#{user[:token]}&user%5Blogin%5D=#{user[:login]}&user%5Bpassword%5D=#{password}&commit=Sign+In"
			call_attr = {verb: "post", user: user, page: '/users/sign_in', req_body: req_body}
			response = http_call(call_attr)
			begin
				cookie = response["set-cookie"].split("\; ").first # Signed in at this point, redirecting to gem_ui
				user.update(online:true, cookie: cookie)
			rescue
				@failures += 1
				return
			end
			call_attr = {verb: "post", user: user, page: '/gem_ui', req_body: ""}
			response = http_call(call_attr)
			user.update(token: Nokogiri::XML(response.body).xpath("//head/meta[@name='csrf-token']").last.attributes["content"].value)
	#	 	username = Nokogiri::XML(response.body).xpath("//li/a[@id='sign_out_link']").text.match(/\(.*\)/)[0].gsub(/[\(\)]/, "").strip
			response
		end
		
		def health_check # To be developed - These are calls made by the Load Balancer
			loop do 
				call_attr = {verb: "post", user_id: user, page: '/heart_beat/refresh'}
				sleep 5
			end
		end

		def heartbeat_call user
			call_attr = {verb: "post", user_id: user, page: '/heart_beat/refresh'}
			response = http_call(call_attr)
			sim_connection "Event.create(user_id: user[:id], event: 'heartbeat', response_code: response.code)"
		end

		def pre_sign_in
			uri = URI.parse @protocol + "://" + @host   # Simulates the first contact to GEM app, redirects to sign-in page
			http = Net::HTTP.new(uri.host, uri.port)
			if @conn["ssl"]
				http.use_ssl = true
	 			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	 			http.open_timeout = 10
	 		end
	 		request = Net::HTTP::Get.new(uri.request_uri)
	 		response = Timeout.timeout(5){ http.request(request) }
	 		return response["set-cookie"].split("\; ").first unless response["set-cookie"].nil?
		end

		def http_call call_attr			
			headers = gem_headers(call_attr[:user], call_attr[:page])
			uri = URI.parse("#{@protocol}://" + @host + call_attr[:page])
			http = Net::HTTP.new(uri.host, uri.port)
			if @conn["ssl"]
				http.use_ssl = true
		 		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
		 		http.open_timeout = 10
		 	end
	 		request = eval "Net::HTTP::#{call_attr[:verb].capitalize}.new(uri.path, headers)"
	 		request.body = call_attr[:req_body] unless call_attr[:req_body].blank?
	 		response = http.request(request)
		end
		
		def get_users
			users = []
			User.all.each do |user|
				users << user.as_json.symbolize_keys
			end
			users#.shuffle!
		end

		def gem_headers user, page
			header = {
				"Accept" =>	"text/html, application/xhtml+xml, */*",
				"Referer" => "#{@protocol}://" + @host + page,
				"Accept-Language" => "en-US",
				"User-Agent" =>	"Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; WOW64; Trident/6.0)",
				"DNT" => "1",
	#			"Accept-Encoding" => "gzip, deflate",
				"Host" => @host,
				"Cookie" =>	user.cookie,
				"Connection" =>	"Keep-Alive",
				"Cache-Control" => "no-cache"
			}
			header["Accept"] = "*/*" if page == '/queues/queue_refresh'
		#	header["Referer"] = "#{@protocol}://" + host + "/gem_ui"# unless page == '/users/sign_in'
			header["x-requested-with"] = "XMLHttpRequest" unless page == '/users/sign_in'
			header["x-csrf-token"] = user.token unless user.token.blank?
			header
		end

		def sim_connection(statement)
			ActiveRecord::Base.connection_pool.with_connection do
				eval statement
			end
		end
	
	end
end



