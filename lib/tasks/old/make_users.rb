namespace :make_users do

	def populate
		names = YAML.load_file 'users.yml'
	end
end
