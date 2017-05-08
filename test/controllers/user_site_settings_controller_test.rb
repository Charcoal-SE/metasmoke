require 'test_helper'

class UserSiteSettingsControllerTest < ActionController::TestCase
  test "should list my preferences" do
    sign_in users(:approved_user)
    get :index

    assert_not_nil assigns(:preferences)
    assert_response 200
  end

  test "should list another users preferences" do
    sign_in users(:approved_user)
    assert_raise ActionController::RoutingError do
      get :for_user, params: { user: users(:approved_user).id }
    end

    sign_out :user
    sign_in users(:admin_user)
    get :for_user, params: { user: users(:approved_user).id }

    assert_not_nil assigns(:preferences)
    assert_not_nil assigns(:user)
    assert_equal users(:approved_user).id, assigns(:user).id
    assert_response 200
  end

  test "should enable flagging" do
    sign_in users(:approved_user)
    users(:approved_user).add_role :flagger
    post :enable_flagging, params: { enable: true }

    assert_equal "ok", JSON.parse(response.body)['status']
    assert_response 200
  end

  test "should get new" do
    sign_in users(:approved_user)
    get :new

    assert_not_nil assigns(:preference)
    assert_response 200
  end

  test "should create preference" do
    sign_in users(:approved_user)

    assert_difference "UserSiteSetting.count" do
      post :create, params: { user_site_setting: { max_flags: 10, sites: [sites(:Site_1).id] }}
    end

    assert_not_nil assigns(:preference)
    assert_response 302
  end

  test "should refuse to create preference with no sites" do
    sign_in users(:approved_user)
    post :create, params: { user_site_setting: { max_flags: 10, sites: [] }}

    assert_response 422
  end

  test "should get edit" do
    sign_in users(:approved_user)
    get :edit, params: { id: user_site_settings(:one).id }

    assert_not_nil assigns(:preference)
    assert_response 200
  end

  test "should update preference" do
    sign_in users(:approved_user)
    patch :update, params: { user_site_setting: { max_flags: 11, sites: [sites(:Site_1).id] }, id: user_site_settings(:one).id }

    assert_not_nil assigns(:preference)
    assert_response 302
  end

  test "should destroy preference" do
    sign_in users(:approved_user)

    assert_difference "UserSiteSetting.count", -1 do
      delete :destroy, params: { id: user_site_settings(:one).id }
    end

    assert_not_nil assigns(:preference)
    assert_response 302
  end
end
