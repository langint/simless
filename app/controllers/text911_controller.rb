class Text911Controller < ApplicationController

GWA_BASE_URL = "10.32.28.212"

	def index
	
	end

	def show
		server_port = params[:id].next
		url = "http://#{GWA_BASE_URL}:808#{server_port}/api"
		uri = URI.parse(url)
#		response = Net::HTTP.get_response(uri)
		render plain: 'response.body'
	end

end
