# Redis Schema:

HASH posts/<id> (Post)
        body: body,
        title: title,
        reason_weight: reasons.map(&:weight).reduce(:+),
        created_at: created_at,
        username: username,
        link: link,
        site_site_logo: site.try(:site_logo),
        stack_exchange_user_username: stack_exchange_user.try(:username),
        stack_exchange_user_id: stack_exchange_user.try(:id),
        flagged: flagged?,
        site_id: site_id,
        post_comments_count: comments.count,
        why: why

ZSET posts/<id>/reasons (Post.reasons reason_name, score: weight)
SET reasons/<id> (Reason.all.map(&:id))
SET all_posts (Post.all.map(&:id))
ZSET posts (Post.all id, score: created_at.to_i)
SET tps (Post.where(is_tp:true).map(&:id))
SET fps (Post.where(is_fp:true).map(&:id))
SET naas (Post.where(is_naa:true).map(&:id))
SET nolink (Post.where(link:nil).map(&:id))
SET questions (Post.all.to_a.select(&:question?).map(&:id))
SET answers (Post.all.to_a.select(&:answer?).map(&:id))
SET autoflagged (Post.all.to_a.select(&:flagged?).map(&:id))
SET sites/<id>/posts (Site.find(<id>).posts.map(&:id))
feedbacks.each(&:populate_redis)
deletion_logs.each(&:update_deletion_data)
