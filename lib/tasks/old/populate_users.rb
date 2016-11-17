namespace :populate_users do

ENTRY = %w( word word word word sentence )

	desc "Resets calls to initial status"
    task :do_it  => :environment do
    	get_users.each do |user|
    		user[:name] = Faker::Name.first_name + " " + Faker::Name.last_name
    		user[:email] = Faker::Internet.email
	    	User.create(user)
	    end
    end

	def get_users
		user_list = YAML.load_file('lib/users_psaps.yml')
		users = []
		user_list.each do |user|
			users << {login: user.keys.first, password: "pa44word", psap: user.values.first}
		end
		users
	end



end
