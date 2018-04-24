SELECT
  (COUNT(DISTINCT IF(t.is_tp, t.id, NULL)) / COUNT(DISTINCT t.id)) * 100 AS accuracy
FROM (
  SELECT
    DISTINCT x.id,
    x.is_tp,
    x.is_fp,
    x.is_naa,
    x.fc_id
  FROM (
    SELECT
      fc.id AS 'fc_id',
      p.id,
      p.is_tp,
      p.is_fp,
      p.is_naa
    FROM flag_conditions AS fc
      INNER JOIN flag_conditions_sites AS fcs ON fcs.flag_condition_id = fc.id
      INNER JOIN (
        SELECT
          posts.id,
          posts.is_tp,
          posts.is_fp,
          posts.is_naa,
          posts.user_reputation,
          posts.site_id,
          SUM(reasons.weight) AS reason_weight,
          COUNT(DISTINCT reasons.id) AS reason_count
        FROM posts
          INNER JOIN posts_reasons ON posts.id = posts_reasons.post_id
          INNER JOIN reasons ON reasons.id = posts_reasons.reason_id
        GROUP BY posts.id
    ) AS p ON
      p.reason_count >= fc.min_reason_count AND
      p.user_reputation <= fc.max_poster_rep AND
      p.reason_weight >= fc.min_weight AND
      p.site_id = fcs.site_id
    WHERE
      fc.user_id = :user_id AND
      fc.flags_enabled = TRUE
  ) AS x
) AS t;