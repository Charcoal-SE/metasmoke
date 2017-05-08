require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  test 'names should be array of symbols' do
    assert Role.names.count > 0
    assert Role.names.select { |r| r.is_a? Symbol } == Role.names
  end
end
