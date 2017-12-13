# frozen_string_literal: true

module API
  class CommitStatusesAPI < API::Base
    prefix :commit_statuses

    get '/' do
      std_result CommitStatus.all.order(id: :desc), filter: 'GGLIFMJJOLIGGNFGINNMOFNIGGMMMJKIFGKFJ'
    end
  end
end
