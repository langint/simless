class SimulationController < ApplicationController
  
  include Simulator

  
  def index
    @env = Simulator.default_env
  end

  def show
    @env = Simulator.default_env
    case params[:id]
    when 'dashboard'
      render :dashboard
    when 'start'
      Event.delete_all
      User.update_all(online:false)
      Rails.cache.write("sim_status", "running")
      Status.first.update(status: 'running')
      sim = Simulator::Sim.new(@env)
      conn_health = server_connected?(sim)
      unless conn_health == "Success"
        render json: { failures: conn_health }
        return
      end
      p 'starting'
      Thread.new{sim.start_simulation}
      failures = Event.where(event: 'failure').count
      payload = {timestamp: Time.now, iss: "FrontEnd Simulator"}
      token = JWT.encode(payload, nil, 'none')
      p token

      render json: { token: token, failures: failures}
    when 'stop'
      Rails.cache.write("sim_status", "stopped")
      Status.first.update(status: 'stopped')
      sleep Status.first.refresh_interval
      User.update_all(online:false)
      render plain: "Similation terminated"
    when 'monitor'
        timestamp = JWT.decode(params[:token], nil, false).first["timestamp"].to_time
        timeframe = (Status.first.refresh_interval.seconds.ago..Time.now)
        elapsed = (Time.now - timestamp.to_time).round(2)
        events = Event.where(created_at: timeframe) 
        if events.count > 0
          arr = events.map{|e| e.response_time}.compact
          response_time = ( 1000 * (arr.inject(:+) / events.count) ).to_i# in milliseconds
          max_response_time = (1000 * arr.max).to_i
        else
          response_time = 0
        end       
        traffic = ( events.count / elapsed.to_f).round(2)
        failures = failures = Event.where(event: 'failure').count
        payload = {timestamp: Time.now, iss: "FrontEnd Simulator"}
        token = JWT.encode(payload, nil, 'none')
        clients = User.where(online: true).count
        data = {count: events.count, failures: failures, traffic: traffic, clients_online: clients, token: token, response_time: response_time, max_response_time: max_response_time, refresh_rate: Status.first.refresh_interval, timestamp: Time.now.to_i}
        render json: data 
    end
  end

  def start_interception
    byebug
    last_event = Event.last.blank? ? 0 : Event.last.id
  end

  def refresh_sim
    last_event = Rails.cache.fetch('last_event')
    events = Event.where("id > ?", last_event)
    render json: events.as_json
  end

  def new

  end

  def edit 
  end

  def update
    unless Status.first.send(params[:id].to_sym) == params[:value].to_i 
      Status.first.update(params[:id].to_sym => params[:value].to_i)
      if params[:id] == 'pool_size' && Status.first.status == 'running' 
        Simulator::Sim.new.change_load
      end
    end
    render nothing: true
  end

  def destroy
    User.update_all(online: false)
    render nothing: true
  end

  def settings
    environments = YAML.load_file("lib/settings.yml")
    @env = environments.select{|e| e['default']}
    @env_list = environments.map{|e| {id: e["id"], name: e["name"], default: e["default"]}}
    @fe_connections = Connection.where(side:'front').order(:id)
    @be_connections = Connection.where(side:'back').order(:id)
  end

  def system_status
    
  end

  def connections
      @fe_connections = Connection.where(side:'front').order(:id)
      @be_connections = Connection.where(side:'back').order(:id) 
      render 'connections', layout: false
  end

  def save_connections
    arr = []
    params[:data].each do |k, v|
      arr << v
      Connection.find(k.to_i).update(v.symbolize_keys)
    end
    render json: arr
  end

  def change_tab
    case params[:tab]
    when 'simulation'
      render 'connections', layout: false
    when 'connections'
      redirect_to :connections
    when 'analysis' 
      render 'connections', layout: false
    when 'system_status'
      render 'system_status', layout: false
    end
  end

######### LANDING PAGE EXPERIMENTS
  def landing
  end

##############

  private
  
  def server_connected? sim
    begin
      response = sim.connection_test(@env[:id], 'front')
    rescue => e
      response = e.message
    end
    response
  end

end
