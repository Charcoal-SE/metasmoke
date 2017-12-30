# frozen_string_literal: true

module API
  class DebugAPI < API::Base
    get '/' do
      { params: params, ts: DateTime.now, filters: FILTERS }
    end

    get 'filter' do
      { fields: Filterator::V2.fields_from_filter(params[:filter]) }
    end
  end
end
