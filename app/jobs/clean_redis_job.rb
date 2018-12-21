# frozen_string_literal: true

class CleanRedisJob < ApplicationJob
  queue_as :default

  def perform
    @keys = []
    api_key_cache = {} # id => APIKey
    thread = Thread.new {}
    Post.eager_load(:stack_exchange_user).eager_load(:site).eager_load(:comments).eager_load(:reasons).eager_load(:flag_logs).eager_load(:feedbacks).find_in_batches(batch_size: 250) do |posts|
      thread.join
      thread = Thread.new do
        redis.pipelined do
          posts.each do |post|
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
              post_comments_count: post.comments.length, # post.comments.count,
              why: post.why
            }
            redis.hmset("posts/#{post.id}", *post_hash.to_a)

            reason_names = post.reasons.map(&:reason_name)
            reason_weights = post.reasons.map(&:weight)
            redis.zadd(ck("posts/#{post.id}/reasons"), reason_weights.zip(reason_names)) unless post.reasons.empty?

            post.feedbacks(&:populate_redis)
            nil
          end
          nil
        end
      end
      GC.start
      nil
    end

    redis.pipelined do
      DeletionLog.eager_load(:post).find_each do |dl|
        redis.hset("posts/#{dl.post.id}", 'deleted_at', dl.created_at.to_s) if dl.is_deleted
      end
    end

    redis.pipelined do
      Reason.find_each do |i|
        redis.sadd(ck('reasons'), i.id)
        redis.sadd(ck("reasons/#{i.id}"), i.posts.select(:id).map(&:id))
      end
    end

    redis.pipelined do
      SiteSetting.find_each do |ss|
        redis.set ck("site_settings/#{ss.name}"), ss.value
      end
    end

    redis.pipelined do
      ReviewItem.eager_load(:queue).find_each do |ri|
        redis.sadd ck('review_queues'), ri.queue.id
        if ri.completed
          redis.srem ck("review_queue/#{ri.queue.id}/unreviewed"), ri.id
        else
          redis.sadd ck("review_queue/#{ri.queue.id}/unreviewed"), ri.id
        end
      end
    end

    redis.pipelined do
      ReviewQueue.find_each do |rq|
        redis.sadd ck('review_queues'), rq.id
      end
    end

    [['posts', Post], ['reasons', Reason], ['feedbacks', Feedback]].each do |str, type|
      ids = ActiveRecord::Base.connection.select_all("SELECT id FROM #{str}").rows.flatten
      redis.scan_each(match: "#{str}/*") do |elem|
        redis.del elem unless ids.include?(elem.split('/')[1].to_i)
      end
    end

    Rails.logger.info @keys
    @keys.each do |key|
      Rails.logger.warn "WARNING: Could not copy key #{key}. cleanups/#{key} exists? #{redis.exists "cleanups/#{key}"} | #{key} exists? #{redis.exists key}" unless redis.exists "cleanups/#{key}"
      redis.rename "cleanups/#{key}", key unless redis.exists "cleanups/#{key}"
    end
    @keys = []
  end

  private

  def ck(key)
    @keys ||= []
    @keys.push(key)
    "cleanups/#{key}"
  end
end
