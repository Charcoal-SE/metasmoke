# frozen_string_literal: true

class MetricsUpdateJob < ApplicationJob
  queue_as :default

  PATH_NORMALS = {
    %r{/flagging/conditions/\d+/edit} => '/flagging/conditions/:id/edit',
    %r{/flagging/conditions/\d+/enable} => '/flagging/conditions/:id/enable',
    %r{/flagging/conditions/\d+} => '/flagging/conditions/:id',
    %r{/flagging/preferences/\d+/edit} => '/flagging/preferences/:id/edit',
    %r{/flagging/users/\d+/logs} => '/flagging/users/:id/logs',
    %r{/reason/\d+} => '/reasons/:id',
    %r{/domains/\d+} => '/domains/:id',
    %r{/domains/tags/\d+} => '/domains/tags/:id',
    %r{/spammers/\d+} => '/spammers/:id',
    %r{/api/w/post/\d+/feedback} => '/api/w/post/:id/feedback',
    %r{/api/posts/[\d;]+} => '/api/posts/:ids',
    %r{/review/[\w-]+/\d+} => '/review/:queue/:id',
    %r{/posts/uid/[^/]+/\d+} => '/posts/uid/:api_param/:native_id',
    %r{/post/\d+} => '/post/:id',
    %r{/feedback/\d+/delete} => '/feedback/:id/delete',
    %r{/comments/\d+/delete} => '/comments/:id/delete',
    %r{/smoke_detector/\d+/statistics} => '/smoke_detector/:id/statistics',
    %r{/spammers/dead/\d+} => '/spammers/dead/:id'
  }.freeze

  def perform(path, db_runtime)
    normalized_path = PATH_NORMALS.select do |pattern, result|
      pattern.match?(path) || result
    end.first[1]
    normalized_path = path if normalized_path.nil?
    query = QueryAverage.find_or_create_by(path: normalized_path)
    query.average = (query.average * query.counter + db_runtime) / (query.counter += 1)
    query.save
  end
end
