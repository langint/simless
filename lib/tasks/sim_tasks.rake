namespace :sim_tasks do
	

  	desc "Load history to Runtime"
    task :load_history_to_runtime  => :environment do
    	file = "lib/documents/history_response.json"
		messages = JSON.parse(File.read file)["TCS.QueryConversationHistoryResult"]["TCS.messages"]
		messages.each do |mes|
			mes.keys.each do |k|
				new_key = k.sub("TCS.","").underscore
				mes[new_key] = mes[k]
				mes.delete(k)
			end
			Runtime.create(mes)
		end
    end

end
