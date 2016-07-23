require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest
  include Devise::TestHelpers

  test "shouldn't allow unauthenticated users to write" do
    sign_out(:users)
    put :create_feedback, :id => 23653, :type => 'tpu-'
    json = JSON.parse(@response.body)
    assert_response(401)
    assert_equal 401, json['error_code']
    assert_equal 'unauthorized', json['error_name']
  end

  test "should return created and post feedback" do
    sign_in users(:admin_user)
    put :create_feedback, :id => 23653, :type => 'tpu-'
    assert_nothing_raised JSON::ParserError do
      JSON.parse(@response.body)
    end
    assert_response(201)
  end
end
