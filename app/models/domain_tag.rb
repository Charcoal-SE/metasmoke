# frozen_string_literal: true

class DomainTag < ApplicationRecord
  include Websocket

  has_and_belongs_to_many :spam_domains
  has_and_belongs_to_many :posts
  has_many :abuse_reports, as: :reportable

  scope(:standard, -> { where(special: false) })
  scope(:special, -> { where(special: true) })

  def merge_into(master)
    master.spam_domains += (spam_domains.to_a - master.spam_domains.to_a)
    master.posts += (posts.to_a - master.posts.to_a)

    spam_domains.clear
    posts.clear

    destroy
  end
end
