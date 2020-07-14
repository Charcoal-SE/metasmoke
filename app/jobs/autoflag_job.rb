# frozen_string_literal: true

class AutoflagJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find(post_id)
    Rails.logger.warn "[autoflagging] #{post.id}: thread begin"
    # Trying to autoflag in a different thread while in test
    # can cause race conditions and segfaults. This is bad,
    # so we completely suppress the issue and just don't do that.
    post.autoflag unless Rails.env.test?
    post.spam_wave_autoflag unless Rails.env.test?
    redis.hset("posts/#{post.id}", 'flagged', post.flagged?)
  end
end
