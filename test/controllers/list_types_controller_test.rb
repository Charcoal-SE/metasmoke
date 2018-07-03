require 'test_helper'

class ListTypesControllerTest < ActionController::TestCase
  test 'all routes should require admin access' do
    sign_in users(:approved_user)
    Rails.sensible_routes.controller(:list_types).each do |rt|
      params = {}
      params[:id] = list_types(:notifications).id if rt.parameters.include? :id

      send rt.verb.downcase.to_sym, rt.url_details[:action], params: params

      assert_response 302
      assert_redirected_to missing_privileges_path(required: 'admin')
    end
  end

  test 'index should show a list of existing types' do
    sign_in users(:admin_user)
    get :index
    assert_response 200
    assert_not_nil assigns(:list_types)
  end

  test 'create should add a new record' do
    sign_in users(:admin_user)
    assert_difference 'ListType.count' do
      post :create, params: { list_type: { name: 'something borrowed', description: 'something blue' } }
    end
    assert_not_nil assigns(:list_type)
    assert_not_nil assigns(:list_type).id
    assert_not_nil flash[:success]
    assert_nil flash[:danger]
    assert_response 302
    assert_redirected_to list_types_path
  end

  test 'update should edit an existing record' do
    sign_in users(:admin_user)
    assert_no_difference 'ListType.count' do
      patch :update, params: { id: list_types(:notifications).id,
                               list_type: { name: 'something old', description: 'something new' } }
    end
    assert_not_nil assigns(:list_type)
    assert_response 302
    assert_not_nil flash[:success]
    assert_nil flash[:danger]
    assert_redirected_to list_types_path
  end

  test 'destroy should remove an existing type' do
    sign_in users(:admin_user)
    assert_difference 'ListType.count', -1 do
      delete :destroy, params: { id: list_types(:notifications) }
    end
    assert_response 302
    assert_redirected_to list_types_path
    assert_not_nil flash[:success]
    assert_nil flash[:danger]
  end
end
