class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
#  protect_from_forgery with: :exception
    before_action :set_the_stage #, only: [:index, :settings, :show]

	def set_the_stage
    	@mode_profiles = YAML.load_file('lib/settings.yml')
    end
  
end
