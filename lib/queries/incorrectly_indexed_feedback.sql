SELECT
  post_id,
  tp_count,
  fp_count,
  naa_count
FROM (
  SELECT
   posts.id AS post_id,
   posts.is_tp AS is_tp,
   posts.is_fp AS is_fp,
   posts.is_naa AS is_naa,
   COUNT(DISTINCT IF(feedbacks.feedback_type LIKE 't%', feedbacks.id, NULL)) AS tp_count,
   COUNT(DISTINCT IF(feedbacks.feedback_type LIKE 'f%', feedbacks.id, NULL)) AS fp_count,
   COUNT(DISTINCT IF(feedbacks.feedback_type LIKE 'n%', feedbacks.id, NULL)) AS naa_count
  FROM p_posts AS posts
   INNER JOIN p_feedbacks AS feedbacks ON posts.id = feedbacks.post_id
  WHERE
   posts.is_tp = TRUE AND
   (posts.is_fp = TRUE OR posts.is_naa = TRUE) AND
   feedbacks.is_invalidated = FALSE
  GROUP BY posts.id
) AS feedback_info
WHERE
  (tp_count = 0 AND is_tp = TRUE) OR
  (fp_count = 0 AND is_fp = TRUE) OR
  (naa_count = 0 AND is_naa = TRUE)
ORDER BY post_id DESC;