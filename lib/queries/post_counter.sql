SELECT TRUNCATE(weight, -1), COUNT(id) FROM
(SELECT posts.id, posts.is_tp, SUM(reasons.weight) AS weight FROM posts INNER JOIN posts_reasons ON posts.id = posts_reasons.post_id
INNER JOIN reasons ON posts_reasons.reason_id = reasons.id GROUP BY posts.id) AS posts_weights
GROUP BY TRUNCATE(weight, -1)
ORDER BY TRUNCATE(weight, -1) ASC;