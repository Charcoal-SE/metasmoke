require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test "should get index" do
    get :search_results
    assert_response :success
    assert_not_nil assigns(:results)
  end

  test "should search by site" do
    site = Post.last.site

    get :search_results, params: { :site => site.site_name }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal assigns(:results), assigns(:results).select { |p| p.site_id == site.id }
  end

  test "should search by reputation" do
    get :search_results, params: { :user_rep_direction => ">=", :user_reputation => 10 }
    assert_response :success
    assert_not_nil assigns(:results)
    assert_equal assigns(:results), assigns(:results).select { |p| p.user_reputation >= 10 }
  end

  test "should search by false positive" do
    get :search_results, params: { :feedback => "false positive" }
    assert_response :success
    assert_equal assigns(:results), assigns(:results).select { |p| p.is_fp }
  end
end
