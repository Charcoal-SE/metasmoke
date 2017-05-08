require 'test_helper'

class GraphsControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response 200
  end

  test 'should get reports by hour' do
    get :reports_by_hour
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get reports by site' do
    get :reports_by_site, params: { timeframe: 'all' }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get reports by hour of day' do
    get :reports_by_hour_of_day, params: { timeframe: 'all' }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get time to deletion' do
    get :time_to_deletion
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get flagging results' do
    get :flagging_results
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get flagging timeline' do
    get :flagging_timeline
    JSON.parse(response.body)
    assert_response 200
  end
end
