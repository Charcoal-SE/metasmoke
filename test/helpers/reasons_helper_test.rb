# frozen_string_literal: true

class ReasonsHelperTest < ActionView::TestCase
  test 'should check for inactive reasons' do
    ReasonsHelper.check_for_inactive_reasons
  end

  test 'should calculate weights for flagging' do
    ReasonsHelper.calculate_weights_for_flagging
  end
end
