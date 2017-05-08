require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test 'should get index' do
    get :search_results
    assert_response :success
    assert_not_nil assigns(:results)
  end

  test 'should search by site' do
    site = Post.last.site

    get :search_results, params: { site: site.site_name }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal assigns(:results), assigns(:results).select { |p| p.site_id == site.id }
  end

  test "should search by reputation" do
    get :search_results, params: { user_rep_direction: ">=", user_reputation: 10 }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal assigns(:results), assigns(:results).select { |p| p.user_reputation >= 10 }
  end

  test "should search by reputation with graph" do
    get :search_results, params: { user_rep_direction: ">=", user_reputation: 10, option: 'graph' }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal assigns(:results), assigns(:results).select { |p| p.user_reputation >= 10 }
  end

  test "should search by false positive" do
    get :search_results, params: { feedback: "false positive" }
    assert_response :success
  end

  test "should search by false positive with graph" do
    get :search_results, params: { feedback: "false positive", option: 'graph' }
    assert_response :success
  end

  test 'should search by regex' do
    sign_in User.first

    get :search_results, params: { title: "foo", title_is_regex: true, title_is_inverse_regex: true }
    assert_response :success
  end
end
