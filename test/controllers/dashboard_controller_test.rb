# frozen_string_literal: true

require 'test_helper'

class DashboardControllerTest < ActionController::TestCase
  test "should work for anonymous users" do
    get :new_dash
    assert_response :success
  end

  test "should work for flaggers" do
    sign_in users(:unapproved_user)
    get :new_dash
    assert_response :success
  end

  test "should work for reviewers" do
    sign_in users(:approved_user)
    get :new_dash
    assert_response :success
  end
end
