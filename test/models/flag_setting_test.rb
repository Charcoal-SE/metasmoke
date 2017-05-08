require 'test_helper'

class FlagSettingTest < ActiveSupport::TestCase
  test 'index notation should work' do
    key = FlagSetting.first.name
    assert FlagSetting[key] == FlagSetting.first.value
  end
end
