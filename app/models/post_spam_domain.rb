# frozen_string_literal: true

class PostSpamDomain < ApplicationRecord
  self.table_name = 'posts_spam_domains'
  belongs_to :post
  belongs_to :spam_domain
  belongs_to :added_by, class_name: 'User'

  def custom_delete
    self.class.where(attributes).delete_all
  end
end
