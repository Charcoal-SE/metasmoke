class Reason < ActiveRecord::Base
  has_and_belongs_to_many :posts
  has_many :feedbacks, :through => :posts

  def tp_percentage
    # I don't like the .count.count, but it does get the job done
    count = self.feedbacks.where("feedback_type LIKE '%tp%'").group("posts.id").count.count

    return (count.to_f / self.posts.count.to_f).to_f
  end
  def fp_percentage
    count = self.feedbacks.where("feedback_type LIKE '%fp%'").group("posts.id").count.count
    return (count.to_f / self.posts.count.to_f).to_f
  end
end
