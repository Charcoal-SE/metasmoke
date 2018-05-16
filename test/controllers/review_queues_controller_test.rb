# frozen_string_literal: true

require 'test_helper'

class ReviewQueuesControllerTest < ActionController::TestCase
  test 'should get index' do
    sign_in users(:approved_user)
    get :index
    assert_response :success
    assert_not_nil assigns(:queues)
  end

  test 'should get posts review' do
    sign_in users(:approved_user)
    get :queue, params: { name: 'posts' }
    assert_response :success
    assert_not_nil assigns(:queue)
  end

  test 'should get next posts queue item' do
    sign_in users(:approved_user)
    get :next_item, params: { name: 'posts' }
    assert_response :success
  end

  test 'should submit result' do
    sign_in users(:approved_user)
    post :submit, params: { name: 'posts', item_id: review_items(:one), response: 'tp' }
    assert_response :success
    assert_equal 'ok', JSON.parse(@response.body)['status']
  end
end
