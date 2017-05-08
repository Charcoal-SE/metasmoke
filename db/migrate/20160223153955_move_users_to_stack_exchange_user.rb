class MoveUsersToStackExchangeUser < ActiveRecord::Migration[4.2]
  def change
    Post.where("stack_exchange_user_id IS NULL").each do |post|
      next if post.user_link.nil?
      
      begin
        user_id = post.user_link.scan(/\/users\/(\d*)\//).first.first
      rescue
        next
      end

      hash = {site_id: post.site_id, user_id: user_id}
      se_user = StackExchangeUser.find_or_create_by(hash)
      se_user.reputation = post.user_reputation
      se_user.username = post.username

      post.stack_exchange_user = se_user

      se_user.save!
      post.save!
    end
  end
end
