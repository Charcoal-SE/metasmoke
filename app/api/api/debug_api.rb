# frozen_string_literal: true

module API
  class DebugAPI < API::Base
    prefix :debug

    get '/' do
      { params: params, ts: DateTime.now }
    end
  end
end
