require 'test_helper'

class SimulationControllerTest < ActionController::TestCase
#   test "the truth" do
#     assert true
#   end

def test_sanity
    data = {id: 'monitor', token: @token}
    byebug
    	get :show, data
  	assert true
#    flunk "Need real tests"
  end

	test "testing the user update operation" do 
		skip
  		data = {id: 'monitor', token: @token}
    	get :show, data
  		#patch :update, id: User.first[:id]
  	#	assert_response 200
   #    assert_equal eval(response.body).symbolize_keys[:error], "No errors"
  end
	

	def setup
			@token =  "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJ0aW1lc3RhbXAiOiIyMDE2LTAzLTE2IDE1OjEzOjU0IC0wNzAwIiwiaXNzIjoiRnJvbnRFbmQgU2ltdWxhdG9yIn0."
	end

end
