require 'test_helper'

class RegexesControllerTest < ActionController::TestCase
  setup do
    @regex = regexes(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:regexes)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create regex" do
    assert_difference('Regex.count') do
      post :create, regex: { reason: @regex.reason }
    end

    assert_redirected_to regex_path(assigns(:regex))
  end

  test "should show regex" do
    get :show, id: @regex
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @regex
    assert_response :success
  end

  test "should update regex" do
    patch :update, id: @regex, regex: { reason: @regex.reason }
    assert_redirected_to regex_path(assigns(:regex))
  end

  test "should destroy regex" do
    assert_difference('Regex.count', -1) do
      delete :destroy, id: @regex
    end

    assert_redirected_to regexes_path
  end
end
