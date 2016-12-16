require 'test_helper'

class FlagConditionsControllerTest < ActionController::TestCase
  test "should list my flag conditions" do
    sign_in users(:approved_user)
    get :index

    assert_not_nil assigns(:conditions)
    assert_response 200
  end

  test "should list all flag conditions" do
    sign_in users(:approved_user)

    assert_raise ActionController::RoutingError do
      get :full_list
    end

    sign_out :user
    sign_in users(:admin_user)
    get :full_list

    assert_not_nil assigns(:conditions)
    assert_equal FlagCondition.count, assigns(:conditions).count
    assert_response 200
  end

  test "should create new flag condition" do
    sign_in users(:approved_user)

    assert_difference "FlagCondition.count" do
      post :create, :params => { :flag_condition => { :min_weight => 300, :max_poster_rep => 10, :min_reason_count => 4, :sites => [sites(:site_1).id, sites(:site_2).id] }}
    end

    assert_not_nil assigns(:condition)
    assert_response 302
  end

  test "should get edit" do
    sign_in users(:approved_user)
    get :edit, :params => { :id => FlagCondition.last.id }

    assert_not_nil assigns(:condition)
    assert_response 200
  end

  test "should update flag condition" do
    sign_in users(:approved_user)
    patch :update, :params => { :flag_condition => { :min_weight => 301, :max_poster_rep => 11, :min_reason_count => 5, :sites => [sites(:site_1).id] }, :id => FlagCondition.last.id }

    assert_not_nil assigns(:condition)
    assert_response 302
  end

  test "should destroy flag condition" do
    sign_in users(:approved_user)

    assert_difference "FlagCondition.count", -1 do
      delete :destroy, :params => { :id => FlagCondition.last.id }
    end
    assert_not_nil assigns(:condition)
    assert_response 302
  end
end
