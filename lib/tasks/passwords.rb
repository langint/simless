load  'connections.rb'
#require 'debugger'

SAMPLE_USER = 'bassk'

class UserHandler
	def make_password_55 
		arr = %w(comcastop2 comcastop3 burlingtonop1 burlingtonop2 burlingtonop3 phillyop4 phillyop1 phillyop2 phillyop3 glendiveop glendive_two glendiveadmin tcschpbarstow tcschpinland cellcomop1 cellcomop2 )
		arr.each do |login|
				user = User.where(login: login).first
				user.encrypted_password = User.where(login: SAMPLE_USER).first.encrypted_password
				user.save
		end
	end

	def make_users(num)
		names = YAML.load_file 'logins.yml'
		psaps = []
		PsapDetail.all.each{|psap| psaps << psap.id}
		user_list = {"login" => []}
		encrypted_pass = User.where(login: SAMPLE_USER).first.encrypted_password
		num.times do |i|
			user = User.last.dup
			user.id = user.id + 1
			user.encrypted_password = encrypted_pass
			user.login = "sj" + names[i]
			user.psap_detail_id = psaps[Random.new.rand(0..psaps.size-1)]
			user_list["login"] << {user.login => 44}
			user.save
		end
		File.open("users.yml", "w"){|h| h.write user_list.to_yaml}
		puts user_list
	end


end

UserHandler.new.make_users(2000)