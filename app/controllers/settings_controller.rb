class SettingsController < ApplicationController
	include Simulator

	def index
		@env = Simulator.default_env
		@env_list = Simulator.sim_environments.map{|e| {id: e[:id], name: e[:name], default: e[:default]}}
		@api_list = Simulator::API_MESSAGES
	end

	def show
		@env = Simulator.sim_environments.detect{|e| e[:id] == params[:env].to_i}.symbolize_keys
		case params[:id]
		when 'menu'
			p 'menu'
		when 'test'
			environment = Simulator.sim_environments.select{|e| e[:id] == params[:env].to_i}.first
			sim = Simulator::Sim.new(environment)
      		render plain: server_connected?(sim, params[:conn_id])
		else
			'do nothing'
		end
	
	end

	def new

	end

	def edit
		@env = Simulator.sim_environments.detect{|e| e[:id] == params[:id].to_i}.symbolize_keys
		render 'connections', layout: false
	end

	def update
		id = params[:id].to_i
		extra = %w( controller action id)
    	extra.each{|e| params.delete(e.to_sym)}
    	environments = Simulator.sim_environments
  		ind = environments.index{| x | x[:id] == id}
  		
  		if params[:mode] == 'set_default'
  			environments.each_with_index do |e, i|
  				e[:default] = i == id ? true : false
  			end
		else
	  		environments[ind][:connections] = params.symbolize_keys
	  		environments[ind][:connections][:front]["ssl"] = eval(environments[ind][:connections][:front]["ssl"])
	  		environments[ind][:connections][:back]["ssl"] = eval(environments[ind][:connections][:back]["ssl"])
  		end
  		File.open(Simulator::SIM_ENV_SOURCE, 'w') {|f| f.write environments.to_yaml }
    	render plain: id
	end

	def destroy
	end

	private
  
	def server_connected? sim, conn_id
	    begin
	      response = sim.connection_test(@env[:id], conn_id)
	    rescue => e
	      response = e.message
	    end
	    response
  end
end
