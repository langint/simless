require 'uri'
require 'net/http'
require 'byebug'

MAX_CLIENTS = 250
CREDENTIALS = "utf8=%E2%9C%93&authenticity_token=4YpcIC17mSIIf6sg7wWoYf8sQ%2FcAR21ia0sykHhYFYU%3D&user%5Blogin%5D=chpinland&user%5Bpassword%5D=vb66upDgUQr%2BmfESgDKn8w%2C1%2CBkJrD4r5O8Q%2C%2BoD4Vtn64BNi%2FxKU4lJoug&commit=Sign+In"

class Sim

	def launch
		# Authorization
                @uri = 'http://172.31.4.77:8080'
#		@uri = 'http://smsdev-gemapp1.sealab.telecomsys.com:8080/'
		uri = URI.parse(@uri + 'users/sign_in')
		http = Net::HTTP.new(uri.host, uri.port)
		request = Net::HTTP::Post.new(uri.request_uri)
	 	request.body = CREDENTIALS
byebug	 	
response = http.request(request)
	 	cookie = response["set-cookie"].split("\; ").first 	
		
		headers = {
			'host'=> 'smsdev-gemapp1.sealab.telecomsys.com:8080',
			'Connection' => 'keep-alive',
			'Origin'=> 'http://smsdev-gemapp1.sealab.telecomsys.com:8080',
			'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36',
			'Content-Type' => 'application/x-www-form-urlencoded',
			'Accept'=> '*/*',
			'X-Requested-With' => 'XMLHttpRequest',
			'Referer'=> 'http://smsdev-gemapp1.sealab.telecomsys.com:8080/gem_ui',
			'Accept-Encoding' => 'gzip, deflate',
			'Accept-Language' => 'en-US,en;q=0.8',
			'Cookie' => cookie
		}
		arr = []
		MAX_CLIENTS.times do |i|
  			arr << Thread.new do
	    		make_call(headers, i) 
      		end
		end
		puts Thread.list
    	arr.each {|t| t.join}

	end


	private

	def get_users
		User.all.map(&:login)
	end

	def make_call headers, i
		r = Random.new
		loop do
			uri = URI.parse(@uri + 'queues/refresh_queue')
			http = Net::HTTP.new(uri.host, uri.port)
			request = Net::HTTP::Post.new(uri.request_uri, headers)
		 	request.body = "psap_id=P06071507"
		 	response = http.request(request)
                        puts response.code
			sleep r.rand(1..5)
		end
	end

end

simulation = Sim.new.launch
