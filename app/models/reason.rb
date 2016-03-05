class Reason < ActiveRecord::Base
  has_and_belongs_to_many :posts
  has_many :feedbacks, :through => :posts

  def tp_percentage
    # I don't like the .count.count, but it does get the job done

    count = self.posts.where(:is_tp => true).count

    return (count.to_f / self.posts.count.to_f).to_f
  end

  def fp_percentage
    count = self.posts.where(:is_fp => true).count

    return (count.to_f / self.posts.count.to_f).to_f
  end
end
