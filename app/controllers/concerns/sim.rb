require 'active_support/concern'

module Sim
	extend ActiveSupport::Concern
	require 'uri'

	ENVIRONMENT = "PRE" # Set it either "PRE" or "LAB"
	SSL = true
	URL_ADDRESS = ENVIRONMENT == "LAB" ? "smsdev-gemapp1.sealab.telecomsys.com:8080" : "smspre-est-gemapp1.xypoint.com:8080"
	MAX_CLIENTS = 1
	REFRESH_RATE = 2.0
	MONITOR_RATE = 1
	SHOW_SIGNIN_RESPONSE = false
	SHOW_REFRESH_RESPONSE = false
	HTTPS_ADDRESS = "172.31.4.77"
	USERS_LIST = 'lib/users_psaps.yml'
	PW44 = "fw3P3BBgfHazva1gXC3KkQ%2C1%2C0dwQgxw2Efk%2Cf1T8XXrYl8nfAVgE0qVTug"
	PW55 = "v5viztbjI%2FDJ6WVAt1aotw%2C1%2CE7pX8RHlRtA%2CnwsV74ZtlBUb23x2rBenBA"

	
	def sim_monitor
	    loop do
	    	Thread.current.kill unless Rails.cache.read('sim_status') == 'running'
	    	events = Event.where(created_at: 3.seconds.ago..Time.now) 
	  		puts events.count
	  		sleep 3
	    end
  	end

	def self.start_simulation
		p "From inside Sim class: #{Event.count}"
		Thread.list.each{ |t| t.kill if t[:type] =~ /^sim_\d*$/}
		puts "After clean-up thread count is #{Thread.list.count}"
		if REFRESH_RATE <1
			puts "Please set REFRESH_RATE greater than 1 second"
			return
		end
		@host = SSL ? HTTPS_ADDRESS : URL_ADDRESS
      	@protocol = SSL ? 'https' : 'http'
      	@users = get_users
      	if @users.size < 1
      		puts "No users online"
      		return 
		end
#      	logoff_users
      	puts "######  SIGNING IN USERS... ##########################"
      	@users.each do |user|
      		response = sign_in user
      		puts "Sign-in response #{response. to_hash}" if SHOW_SIGNIN_RESPONSE
      	end
      	puts "######  LAUNCHING REFRESH CALLS. Symbol | denotes GWA response. Failures will be reported."
		@max_clients.times do |i|
  			byebug
  			Thread.new do
  				Thread.current[:type] = "sim_#{i}"
		   		refresh_calls @users[i]
      		end
		end
	end


#	private

	def health_check
		loop do 
			call_attr = {verb: "post", user: user, page: '/heart_beat/refresh'}
			print "HCHK"
			sleep 5
		end
	end

	def heartbeat_call user
		call_attr = {verb: "post", user: user, page: '/heart_beat/refresh'}
		response = http_call(call_attr)
		print "| heartbeat #{Thread.current[:type]}, Clients: #{Thread.list.count}| "
	end

	def refresh_calls user		 
		sleeptime = Random.new
		refresh_interval = sleeptime.rand( (REFRESH_RATE*0.9)..(REFRESH_RATE*1.1) )
		call_attr = {verb: "post", user: user, page: '/queues/queue_refresh', req_body: "psap_id=#{user[:psap]}"}		
		heartbeat_interval = sleeptime.rand(29..31)
		time_origin = Time.now
		byebug
		loop do
			elapsed_time = (Time.now - time_origin).to_i / heartbeat_interval
			unless elapsed_time < 1
				time_origin = Time.now
				response = heartbeat_call(user)
				byebug
		#		Event.create(user: user[:login], event: 'heartbeat', response_code: response.code)
			end
	#		response = http_call(call_attr)
	#		p "Threads: #{Thread.list.count}, id=#{Thread.current[:type]}"
	#		Event.create(user: user[:login], event: 'refresh', response_code: response.code)
			Thread.current.kill unless Rails.cache.read('sim_status') == 'running'
	#		return if response.code == '302'
			sleep refresh_interval
		end
	end

	def pre_sign_in user
		# Simulates the first contact to GEM app, redirects to sign-in page
		uri = URI.parse @protocol + "://" + @host
		http = Net::HTTP.new(uri.host, uri.port)
		if SSL
			http.use_ssl = true
 			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
 			http.open_timeout = 10
 		end
 		request = Net::HTTP::Get.new(uri.request_uri)
 		response = http.request(request)
 		return response["set-cookie"].split("\; ").first
	end

	def sign_in(user)
	#	prepare_user(user)  # TO BE DONE WITH THE STANDARD SIGN-OFF ROUTINE
		user[:cookie] = pre_sign_in(user)
		# Obtaining the sign-in page with the csrf token 
 		call_attr = {verb: "get", user: user, page: '/users/sign_in', req_body: ""}
 		response = http_call(call_attr)
		password = user[:password] == "pa44word" ? PW44 : PW55
		user[:token] = Nokogiri::XML(response.body).xpath("//head/meta[@name='csrf-token']").last.attributes["content"].value		
		# Signing in (POST)
		req_body = "utf8=%E2%9C%93&authenticity_token=#{user[:token]}&user%5Blogin%5D=#{user[:login]}&user%5Bpassword%5D=#{password}&commit=Sign+In"
		call_attr = {verb: "post", user: user, page: '/users/sign_in', req_body: req_body}
		response = http_call(call_attr)
		user[:cookie] = response["set-cookie"].split("\; ").first # Signed in at this point, redirecting to gem_ui
		call_attr = {verb: "post", user: user, page: '/gem_ui', req_body: ""}
		response = http_call(call_attr)
		user[:token] = Nokogiri::XML(response.body).xpath("//head/meta[@name='csrf-token']").last.attributes["content"].value
	 	username = Nokogiri::XML(response.body).xpath("//li/a[@id='sign_out_link']").text.match(/\(.*\)/)[0].gsub(/[\(\)]/, "").strip
	 	if SSL
	 		puts "User #{user[:login]}, user name #{username} logged in through SSL" if username
	 	else
	 		puts "User #{user[:login]} logged in" if username
	 	end
	 	puts "Redirected to: #{response['location']}" if response.code == '302'
		response
	end

	def http_call call_attr			
		headers = gem_headers(call_attr[:user], call_attr[:page])
		uri = URI.parse("#{@protocol}://" + @host + call_attr[:page])
		http = Net::HTTP.new(uri.host, uri.port)
		if SSL
			http.use_ssl = true
	 		http.verify_mode = OpenSSL::SSL::VERIFY_NONE
	 		http.open_timeout = 10
	 	end
 		request = eval "Net::HTTP::#{call_attr[:verb].capitalize}.new(uri.path, headers)"
 		request.body = call_attr[:req_body] unless call_attr[:req_body].blank?
 		response =http.request(request)
	end
	
	def get_users
		user_list = YAML.load_file('lib/users_psaps.yml')
		user_list.shuffle!
		users = []
		@max_clients = [user_list.size, MAX_CLIENTS].min
		puts "This test will engage #{@max_clients} clients"
		0.upto(@max_clients - 1) do |i|
			users << {login: user_list[i].keys.first, password: "pa44word", psap: user_list[i].values.first}
		end
		users
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
			"Cookie" =>	user[:cookie],
			"Connection" =>	"Keep-Alive",
			"Cache-Control" => "no-cache"
		}
		header["Accept"] = "*/*" if page == '/queues/queue_refresh'
	#	header["Referer"] = "#{@protocol}://" + host + "/gem_ui"# unless page == '/users/sign_in'
		header["x-requested-with"] = "XMLHttpRequest" unless page == '/users/sign_in'
		header["x-csrf-token"] = user[:token] unless user[:token].blank?
		header
	end

	def rate_monitor
		Thread.new do
			loop do
				@cache.rewind
				count = @cache.read.to_i
				puts count
				puts "#{ count / MONITOR_RATE } calls per second on the average"
				@cache.rewind
				@cache.truncate(0)
				sleep MONITOR_RATE
			end
		end
	end

	def prepare_user user
		user_db = User.where(login: user[:login]).first
		user_db.is_online = false
		user_db.locked_at = nil
		user_db.failed_attempts = 0
		user_db.save
	end

	def logoff_users
		@users.each do |user|
			begin
				Session.where(session_id: user[:cookie]).last.delete
				puts "User #{user[:login]} logged off" 
			rescue Exception => e
				"Error while logging off"
			end
		end
	end
	

end



