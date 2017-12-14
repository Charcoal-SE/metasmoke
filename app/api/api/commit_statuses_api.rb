# frozen_string_literal: true

module API
  class CommitStatusesAPI < API::Base
    get '/' do
      std_result CommitStatus.all.order(id: :desc), filter: 'GGOFONNHNJHHIHNJLHHGHGNGGGHLFGGGNNMJFFOL'
    end
  end
end
