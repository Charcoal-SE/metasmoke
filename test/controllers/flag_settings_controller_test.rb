require 'test_helper'

class FlagSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @flag_setting = flag_settings(:one)
  end

  test "should get index" do
    get flag_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_flag_setting_url
    assert_response :success
  end

  test "should create flag_setting" do
    assert_difference('FlagSetting.count') do
      post flag_settings_url, params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    end

    assert_redirected_to flag_setting_url(FlagSetting.last)
  end

  test "should show flag_setting" do
    get flag_setting_url(@flag_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_flag_setting_url(@flag_setting)
    assert_response :success
  end

  test "should update flag_setting" do
    patch flag_setting_url(@flag_setting), params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    assert_redirected_to flag_setting_url(@flag_setting)
  end

  test "should destroy flag_setting" do
    assert_difference('FlagSetting.count', -1) do
      delete flag_setting_url(@flag_setting)
    end

    assert_redirected_to flag_settings_url
  end
end
