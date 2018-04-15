# frozen_string_literal: true

class Site < ApplicationRecord
  include Websocket

  has_many :stack_exchange_users, dependent: :destroy
  has_many :posts, dependent: :nullify
  has_many :flag_logs, dependent: :nullify
  has_many :moderator_sites, dependent: :destroy
  has_and_belongs_to_many :user_site_settings
  has_and_belongs_to_many :flag_conditions

  scope(:mains, -> { where(is_child_meta: false) })
  scope(:metas, -> { where(is_child_meta: true) })
end
