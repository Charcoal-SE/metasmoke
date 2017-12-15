# frozen_string_literal: true

module API
  class DebugAPI < API::Base
    get '/' do
      { params: params, ts: DateTime.now, filters: FILTERS }
    end
  end
end
