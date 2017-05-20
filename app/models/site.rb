class Site < ApplicationRecord
  has_many :stack_exchange_users
  has_many :posts
  has_many :flag_logs
  has_many :moderator_sites
  has_and_belongs_to_many :users
  has_and_belongs_to_many :user_site_settings
  has_and_belongs_to_many :flag_conditions

  scope(:mains, -> { where(is_child_meta: false) })
  scope(:metas, -> { where(is_child_meta: true) })
end
