# frozen_string_literal: true

require 'test_helper'

class SpamDomainsControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_not_nil assigns(:total)
    assert_not_nil assigns(:domains)
    assert_not_nil assigns(:counts)
    assert_response :success
  end

  test 'should deny create to non-smokey clients' do
    post :create
    assert_response :forbidden
  end

  test 'should let smokey create spam domains' do
    post :create, params: { key: smoke_detectors(:smoke_detector_1).access_token, post_id: posts(:post_23601).id,
                            domains: ['test.spam.com'] }
    assert_equal({ 'status' => 'success', 'total_domains' => 1 }, JSON.parse(response.body))
    assert_response :success
  end
end
