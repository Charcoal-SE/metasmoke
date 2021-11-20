# frozen_string_literal: true

require 'test_helper'

class FlagSettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @flag_setting = FlagSetting.first
  end

  test 'should get index' do
    get flag_settings_url
    assert_response :success
  end

  test 'should get new' do
    sign_out :user
    get new_flag_setting_path
    assert_redirected_to missing_privileges_path(required: :admin)

    sign_in users(:admin_user)
    get new_flag_setting_path

    assert_response :success
  end

  test 'should create flag_setting' do
    sign_out :user

    post flag_settings_url, params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    assert_redirected_to missing_privileges_path(required: :admin)

    sign_in users(:admin_user)

    assert_difference('FlagSetting.count') do
      post flag_settings_url, params: { flag_setting: { name: 'such valid', value: 'very setting' } }
    end

    assert_redirected_to flag_settings_path
  end

  test 'should get edit' do
    sign_out :user

    get edit_flag_setting_url(@flag_setting)
    assert_redirected_to missing_privileges_path(required: :admin)

    sign_in users(:admin_user)

    get edit_flag_setting_url(@flag_setting)
    assert_response :success
  end

  test 'should update flag_setting' do
    sign_out :user

    patch flag_setting_url(@flag_setting),
          params: { flag_setting: { name: @flag_setting.name, value: @flag_setting.value } }
    assert_redirected_to missing_privileges_path(required: :admin)

    sign_in users(:admin_user)

    patch flag_setting_url(@flag_setting), params: { flag_setting: { name: 'valid', value: 'also valid' } }
    assert_redirected_to flag_settings_path
  end

  test 'should get audit log' do
    sign_out :user

    get flag_settings_audits_url

    assert_response :success
  end

  test 'should get dashboard' do
    sign_out :user
    get flagging_url
    assert_response :success

    sign_in users(:admin_user)
    get flagging_url
    assert_response :success
  end

  test 'should allow smokey to disable flagging' do
    sign_out :user
    post smokey_disable_url, params: { key: SmokeDetector.first.access_token }

    # Should disable flagging
    assert FlagSetting['flagging_enabled'] == '0'

    # Should be recorded as System having done it
    assert FlagSetting.find_by(name: 'flagging_enabled').audits.last.user_id == -1
  end
end
