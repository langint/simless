require 'uri'
require 'net/http'
require 'active_record'

URL_ADDRESS = "http://smsdev-gemapp1.sealab.telecomsys.com:8080/"

ActiveRecord::Base.establish_connection(adapter:'mysql', database:'gem911db', username: 'gem911dbuser', password: 'pa55word', host:'localhost')

class Session < ActiveRecord::Base
	self.table_name = 'sessions'
end

class User < ActiveRecord::Base
	belongs_to :psap_detail
end

class PsapDetail < ActiveRecord::Base
	has_many :users
end

