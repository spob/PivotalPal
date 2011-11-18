require 'test_helper'

class StoriesControllerTest < ActionController::TestCase
  test "should get split" do
    get :split
    assert_response :success
  end

end
