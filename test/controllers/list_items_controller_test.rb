require 'test_helper'

class ListItemsControllerTest < ActionController::TestCase
  test 'list should list all items from specified list type' do
    get :list, params: { list: list_types(:notifications).name }
    assert_response 200
    assert_not_nil assigns(:type)
    assert_not_nil assigns(:items)
    assert_not assigns(:items).map { |li| li.list_type == assigns(:type) }.any(&:!)
  end

  test 'UI create should require sign in' do
    post :create
    assert_response 302
    assert_redirected_to new_user_session_path
  end

  test 'UI create should require a list type specified' do
    sign_in users(:approved_user)
    assert_no_difference 'ListItem.count' do
      post :create, params: { list_item: { data: '{"some": "JSON data"}' } }
    end
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil flash[:danger]
    assert_equal true, flash[:danger].include?('select a list')
  end

  test 'UI create should deny users without privileges' do
    sign_in users(:approved_user)
    assert_no_difference 'ListItem.count' do
      post :create, params: { list_item: { list_type_id: list_types(:blacklist).id, data: '' } }
    end
    assert_nil flash[:danger]
    assert_response 302
    assert_redirected_to missing_privileges_path(required: list_types(:blacklist).permissions)
  end

  test 'valid UI create should add a record' do
    sign_in users(:approved_user)
    post :create, params: { list_item: { list_type_id: list_types(:notifications).id, data: '{}' } }
    assert_response 302
    assert_redirected_to root_path
    assert_not_nil assigns(:item)
    assert_not_nil assigns(:item).id
    assert_not_nil flash[:success]
    assert_nil flash[:danger]
    assert_nil assigns(:item).smoke_detector
    assert_not_nil assigns(:item).user
  end

  test 'API create should require a valid Smokey token' do
    assert_no_difference 'ListItem.count' do
      post :create, params: { format: :json }
    end
    assert_response 403
    assert_equal 'Go away', response.body
  end

  test 'valid API create should add a record' do
    post :create, params: { format: :json, type: 'notifications', key: smoke_detectors(:smoke_detector_1).access_token,
                            list_item: { data: '{}' } }
    assert_response 200
    assert_not_nil assigns(:item)
    assert_nil assigns(:item).user
    assert_not_nil assigns(:item).smoke_detector
  end
end
