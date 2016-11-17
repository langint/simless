namespace :populate_db do

ENTRY = %w( word word word word sentence )

	desc "Resets calls to initial status"
    task :initial  => :environment do
  # 	Link.delete_all
   # 	Lexunit.delete_all
    	100000.times do |i|
    		entry_type = ENTRY[rand(0..4)]
    		eng = eval("Faker::Lorem.#{entry_type}")
	    	rus = eval("Vydumschik::Lorem.#{entry_type}")
	    	puts "#{eng} : #{rus}"
    		src = EnLex.where(word: eng).first_or_create
    		trg = RuLex.where(word: rus).first_or_create
			Link.create(left_id:src.id, right_id:trg.id)		
	    end
    end

end
