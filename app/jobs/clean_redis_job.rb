# frozen_string_literal: true

class CleanRedisJob < ApplicationJob
  queue_as :default

  def perform
    return if redis.setnx('cleanups/lock', 'true') == 0
    @keys = []
    api_key_cache = {} # id => APIKey
    Post.eager_load(:stack_exchange_user).eager_load(:site).eager_load(:comments).eager_load(:reasons).eager_load(:flag_logs).eager_load(:feedbacks).find_each(batch_size: 1000) do |post|
      redis.pipelined do
        # posts.each do |post|
          redis.sadd ck('tps'), post.id if post.is_tp
          redis.sadd ck('fps'), post.id if post.is_fp
          redis.sadd ck('naas'), post.id if post.is_naa
          if post.link.nil?
            redis.sadd ck('nolink'), post.id
          else
            redis.sadd ck('questions'), post.id if post.question?
            redis.sadd ck('answers'), post.id if post.answer?
          end
          redis.sadd ck('autoflagged'), post.id if post.flagged?
          redis.sadd ck("sites/#{post.site_id}/posts"), post.id
          redis.sadd ck('all_posts'), post.id
          redis.zadd ck('posts'), post.created_at.to_i, post.id
          post_hash = {
            body: post.body,
            title: post.title,
            reason_weight: post.reasons.map(&:weight).reduce(:+),
            created_at: post.created_at,
            username: post.username,
            link: post.link,
            site_site_logo: post.site.try(:site_logo),
            stack_exchange_user_username: post.stack_exchange_user.try(:username),
            stack_exchange_user_id: post.stack_exchange_user.try(:id),
            flagged: post.flagged?,
            site_id: post.site_id,
            post_comments_count: post.comments.length,#post.comments.count,
            why: post.why
          }
          redis.hmset("posts/#{post.id}", *post_hash.to_a)

          reason_names = post.reasons.map(&:reason_name)
          reason_weights = post.reasons.map(&:weight)
          redis.zadd(ck("posts/#{post.id}/reasons"), reason_weights.zip(reason_names)) unless post.reasons.empty?

          post.feedbacks.each do |feedback|
            redis.zadd ck("post/#{post.id}/feedbacks"), 0, feedback.id.to_s
            redis.hmset "feedbacks/#{feedback.id}", *{
              feedback_type: feedback.feedback_type,
              username: feedback.user_name, # feedback.user.try(:username) || feedback.user_name,
              app_name: api_key_cache[feedback.api_key_id] ||= feedback.api_key.try(:app_name),
              invalidated: feedback.is_invalidated
            }
          end
          nil
        # end
        # nil
      end
      # GC.start
      nil
    end

    redis.pipelined do
      Reason.find_each do |i|
        redis.sadd(ck("reasons"), i.id)
        redis.sadd(ck("reasons/#{i.id}"), i.posts.select(:id).map(&:id))
      end
    end

    redis.pipelined do
      SiteSetting.find_each do |ss|
        redis.set ck("site_settings/#{ss.name}"), ss.value
      end
    end

    redis.pipelined do
      ReviewItem.find_each do |ri|
        redis.sadd ck("review_queues"), ri.queue.id
        if completed
          redis.srem ck("review_queue/#{ri.queue.id}/unreviewed"), ri.id
        else
          redis.sadd ck("review_queue/#{ri.queue.id}/unreviewed"), ri.id
        end
      end
    end

    [['posts', Post], ['reasons', Reason], ['feedbacks', Feedback]].each do |str, type|
      ids = type.all.select(:id).map(&:id)
      redis.scan_each(match: "#{str}/*") do |elem|
        redis.del elem unless ids.include?(elem.split('/')[1].to_i)
      end
    end

    @keys.each do |key|
      redis.multi do
        redis.rename key, "pending_deletion/#{key}" if redis.exists key
        redis.rename "cleanups/#{key}", key
      end
      redis.del "pending_deletion/#{key}"
    end
    @keys = []
    redis.del 'cleanups/lock'
  end

  private

  def ck(key)
    @keys ||= []
    @keys.push(key)
    "cleanups/#{key}"
  end
end
