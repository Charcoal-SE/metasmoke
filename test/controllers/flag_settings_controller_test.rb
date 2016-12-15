require 'test_helper'

class FlagSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @flag_setting = flag_settings(:one)
  end

  test "should get index" do
    get flag_settings_url
    assert_response :success
  end

  test "should get new" do
    sign_out :user
    assert_raise ActionController::RoutingError do
      get new_flag_setting_path
    end

    sign_in users(:admin_user)
    get new_flag_setting_path

    assert_response :success
  end

  test "should create flag_setting" do
    sign_out :user

    assert_raise ActionController::RoutingError do
      post flag_settings_url, params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    end

    sign_in users(:admin_user)

    assert_difference('FlagSetting.count') do
      post flag_settings_url, params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    end

    assert_redirected_to flag_setting_url(FlagSetting.last)
  end

  test "should get edit" do
    sign_out :user

    assert_raise ActionController::RoutingError do
      get edit_flag_setting_url(@flag_setting)
    end
    sign_in users(:admin_user)

    get edit_flag_setting_url(@flag_setting)
    assert_response :success
  end

  test "should update flag_setting" do
    sign_out :user

    assert_raise ActionController::RoutingError do
      patch flag_setting_url(@flag_setting), params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    end

    sign_in users(:admin_user)

    patch flag_setting_url(@flag_setting), params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    assert_redirected_to flag_setting_url(@flag_setting)
  end
end
