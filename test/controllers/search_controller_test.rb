# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:results)
  end

  test 'should search by site' do
    site = Post.last.site

    get :index, params: { site: site.site_name }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal(assigns(:results), assigns(:results).select { |p| p.site_id == site.id })
  end

  test 'should search by reputation' do
    get :index, params: { user_rep_direction: '>=', user_reputation: 10 }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal(assigns(:results), assigns(:results).select { |p| p.user_reputation >= 10 })
  end

  test 'should search by reputation with graph' do
    get :index, params: { user_rep_direction: '>=', user_reputation: 10, option: 'graph' }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal(assigns(:results), assigns(:results).select { |p| p.user_reputation >= 10 })
  end

  test 'should search by false positive' do
    get :index, params: { feedback: 'false positive' }
    assert_response :success
  end

  test 'should search by false positive with graph' do
    get :index, params: { feedback: 'false positive', option: 'graph' }
    assert_response :success
  end

  test 'should search by regex' do
    sign_in User.first

    get :index, params: { title: 'foo', title_is_regex: true, title_is_inverse_regex: true }
    assert_response :success
  end

  test 'should search by not autoflagged' do
    get :index, params: { autoflagged: 'No' }
    assert_response :success
    assert_not_nil assigns(:results)
  end
end
