class AddAutoflaggedToPosts < ActiveRecord::Migration[5.1]
  def change
    add_column :posts, :autoflagged, :boolean, default: false

    Post.where(id: (Post.left_joins(:flag_logs)
        .joins("LEFT JOIN (SELECT posts.id AS 'post_id', COUNT(DISTINCT flag_logs.id) AS 'autoflag_count' FROM posts INNER JOIN flag_logs " \
        'ON flag_logs.post_id = posts.id WHERE flag_logs.is_auto = 1 GROUP BY posts.id) AS flag_counts ON flag_counts.post_id = posts.id')
        .where(flag_counts: { autoflag_count: 0 }) +
      Post.left_joins(:flag_logs).where(flag_logs: { post_id: nil })).map(&:id)).update_all(autoflagged: false)
    Post.joins(:flag_logs).where(flag_logs: { is_auto: true }).update_all(autoflagged: true)
  end
end
