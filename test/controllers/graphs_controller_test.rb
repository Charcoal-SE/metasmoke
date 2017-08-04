# frozen_string_literal: true

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

  test 'should get reports by hour cached' do
    get :reports_by_hour, params: { cache: true }
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

  test 'should get time to deletion cached' do
    get :time_to_deletion, params: { cache: true }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get flagging results' do
    get :flagging_results
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get flagging results cached' do
    get :flagging_results, params: { cache: true }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get flagging timeline' do
    get :flagging_timeline
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get flagging timeline cached' do
    get :flagging_timeline, params: { cache: true }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get monthly TTD' do
    get :monthly_ttd
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get monthly TTD cached' do
    get :monthly_ttd, params: { cache: true }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get monthly TTD for 1 month' do
    get :monthly_ttd, params: { months: 1 }
    JSON.parse(response.body)
    assert_response 200
  end

  test 'should get reports' do
    get :reports
    JSON.parse(response.body)
    assert_response 200
  end
end
