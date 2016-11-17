require 'test_helper'

class MonitorTest < ActionDispatch::IntegrationTest
#   test "the truth" do
#     assert true
#   end

	it "Tests logon/logoff in with valid credentials" do
    	byebug
    	app.get "/"

    	p JSON(app.response.body)["clients_online"].to_s + " events " +  JSON(app.response.body)["count"].to_s
    	assert true
    end

def setup
		@token =  "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJ0aW1lc3RhbXAiOiIyMDE2LTAzLTE2IDE1OjEzOjU0IC0wNzAwIiwiaXNzIjoiRnJvbnRFbmQgU2ltdWxhdG9yIn0."
end

end
